RSpec.describe EarlyAccessUser do
  describe ".promote_waiting_list_user" do
    it "creates and returns an early access user" do
      waiting_list_user = create(:waiting_list_user)

      early_access_user = described_class.promote_waiting_list_user(waiting_list_user)

      expect(early_access_user).to have_attributes(
        email: waiting_list_user.email,
        user_description: waiting_list_user.user_description,
        reason_for_visit: waiting_list_user.reason_for_visit,
        source: "admin_promoted",
      )
    end

    it "deletes the WaitingListUser and creates a DeletedWaitingListUser" do
      waiting_list_user = create(:waiting_list_user)

      expect { described_class.promote_waiting_list_user(waiting_list_user) }
        .to change { WaitingListUser.exists?(waiting_list_user.id) }.to(false)
        .and change { DeletedWaitingListUser.where(deletion_type: "promotion").count }.by(1)
    end

    it "does not make any changes if an exception is raised" do
      waiting_list_user = create(:waiting_list_user)
      allow(described_class).to receive(:create!).and_raise(ActiveRecord::RecordInvalid)

      expect { described_class.promote_waiting_list_user(waiting_list_user) }
        .to raise_error(ActiveRecord::RecordInvalid)

      expect(described_class.find_by_email(waiting_list_user.email)).to be_nil
      expect(WaitingListUser.find_by_id(waiting_list_user.id)).to eq(waiting_list_user)
    end
  end

  describe "#destroy_with_audit" do
    it "destroys a user while creating a DeletedEarlyAccessUser record" do
      instance = create(:early_access_user, login_count: 3)

      expect { instance.destroy_with_audit(deletion_type: :unsubscribe) }
        .to change(described_class, :count).by(-1)
        .and change(DeletedEarlyAccessUser, :count).by(1)

      expect(DeletedEarlyAccessUser.last).to have_attributes(
        id: instance.id,
        login_count: instance.login_count,
        user_source: instance.source,
        user_created_at: instance.created_at,
        deletion_type: "unsubscribe",
      )
    end
  end

  describe "#access_revoked?" do
    it "returns true when revoked_at has a value" do
      instance = described_class.new(revoked_at: Time.current)
      expect(instance.access_revoked?).to be(true)
    end

    it "returns false when revoked_at doens't have a value" do
      instance = described_class.new(revoked_at: nil)
      expect(instance.access_revoked?).to be(false)
    end
  end

  describe "#sign_in" do
    it "raises a AccessRevokedError if a user has access revoked" do
      instance = described_class.new(revoked_at: Time.current)
      expect { instance.sign_in(build(:passwordless_session)) }
        .to raise_error(described_class::AccessRevokedError)
    end

    it "updates the last login at value" do
      freeze_time do
        user = create(:early_access_user, last_login_at: 1.day.ago)

        expect { user.sign_in(build(:passwordless_session)) }
          .to change { user.last_login_at }.to(Time.current)
      end
    end

    it "increments login_count value" do
      freeze_time do
        user = create(:early_access_user, last_login_at: 1.day.ago)

        expect { user.sign_in(build(:passwordless_session)) }
          .to change { user.reload.login_count }.by(1)
      end
    end

    it "deletes any other available sessions to prevent concurrent usage" do
      user = create(:early_access_user)
      current_session = create(:passwordless_session, authenticatable: user)
      claimed_session = create(:passwordless_session, authenticatable: user, claimed_at: 1.day.ago)
      pending_session = create(:passwordless_session, authenticatable: user)
      expired_session = create(:passwordless_session, authenticatable: user, expires_at: 1.day.ago)
      other_user_session = create(:passwordless_session)

      expect { user.sign_in(current_session) }
        .to change { Passwordless::Session.exists?(claimed_session.id) }.to(false)
        .and change { Passwordless::Session.exists?(pending_session.id) }.to(false)
        .and(not_change { Passwordless::Session.exists?(current_session.id) })
        .and(not_change { Passwordless::Session.exists?(expired_session.id) })
        .and(not_change { Passwordless::Session.exists?(other_user_session.id) })
    end
  end

  describe "#question_limit" do
    context "when a user doesn't have an individual question limit" do
      let(:user) { build(:early_access_user, individual_question_limit: nil) }

      it "returns the max_questions_per_user config variable" do
        expect(user.question_limit)
          .to eq(Rails.configuration.conversations.max_questions_per_user)
      end
    end

    context "when a user has an individual question limit" do
      let(:user) { build(:early_access_user, individual_question_limit: 100) }

      it "returns the configured limit" do
        expect(user.question_limit).to eq(100)
      end
    end

    context "when a user has unlimited questions" do
      let(:user) { build(:early_access_user, individual_question_limit: 0) }

      it "returns 0" do
        expect(user.question_limit).to eq(0)
      end
    end
  end

  describe "#question_limit_reached?" do
    it "returns false if the the question limit is zero" do
      user = build(:early_access_user, individual_question_limit: 0)
      expect(user.question_limit_reached?).to be(false)
    end

    context "when an individual_question_limit is not set" do
      let(:user) { build(:early_access_user, individual_question_limit: nil, questions_count: 5) }

      it "returns false if the question count is less than the default" do
        allow(Rails.configuration.conversations).to receive(:max_questions_per_user).and_return(10)
        expect(user.question_limit_reached?).to be(false)
      end

      it "returns true if the question count equals the default" do
        allow(Rails.configuration.conversations).to receive(:max_questions_per_user).and_return(5)
        expect(user.question_limit_reached?).to be(true)
      end

      it "returns true if the question count exceeds the default" do
        allow(Rails.configuration.conversations).to receive(:max_questions_per_user).and_return(3)
        expect(user.question_limit_reached?).to be(true)
      end
    end

    context "when the individual_question_limit is not nil" do
      it "returns false if the question count is less than the limit" do
        user = build(:early_access_user, individual_question_limit: 10, questions_count: 5)
        expect(user.question_limit_reached?).to be(false)
      end

      it "returns true if the question count equals the limit" do
        user = build(:early_access_user, individual_question_limit: 5, questions_count: 5)
        expect(user.question_limit_reached?).to be(true)
      end

      it "returns true if the question count exceeds the limit" do
        user = build(:early_access_user, individual_question_limit: 5, questions_count: 10)
        expect(user.question_limit_reached?).to be(true)
      end
    end
  end

  describe "#unlimited_question_allowance?" do
    context "when the individual question limit is present" do
      it "returns true if the individual question limit is zero" do
        user = build(:early_access_user, individual_question_limit: 0)
        expect(user.unlimited_question_allowance?).to be(true)
      end

      it "returns false if the question limit is not zero" do
        user = build(:early_access_user, individual_question_limit: 5)
        expect(user.unlimited_question_allowance?).to be(false)
      end
    end

    context "when the individual question limit is nil" do
      let(:user) { build(:early_access_user, individual_question_limit: nil) }

      it "returns true if the globally configured limit is zero" do
        allow(Rails.configuration.conversations).to receive(:max_questions_per_user).and_return(0)
        expect(user.unlimited_question_allowance?).to be(true)
      end

      it "returns false if the globally configured limit is not zero" do
        allow(Rails.configuration.conversations).to receive(:max_questions_per_user).and_return(10)
        expect(user.unlimited_question_allowance?).to be(false)
      end
    end
  end

  describe "#number_of_questions_remaining" do
    it "raises an error if the user has an unlimited question allowance" do
      user = build(:early_access_user, individual_question_limit: 0)
      expect { user.number_of_questions_remaining }.to raise_error(RuntimeError, "User has unlimited questions allowance")
    end

    it "returns the number of questions remaining if the question limit is not nil" do
      user = build(:early_access_user, individual_question_limit: 20, questions_count: 2)
      expect(user.number_of_questions_remaining).to eq(18)
    end

    it "returns the number of questions remaining if the individual question limit is nil" do
      allow(Rails.configuration.conversations).to receive(:max_questions_per_user).and_return(50)

      user = build(:early_access_user, individual_question_limit: nil, questions_count: 10)
      expect(user.number_of_questions_remaining).to eq(40)
    end

    it "caps the number of questions remaining at 0" do
      allow(Rails.configuration.conversations).to receive(:max_questions_per_user).and_return(50)

      user = build(:early_access_user, individual_question_limit: nil, questions_count: 100)
      expect(user.number_of_questions_remaining).to eq(0)
    end
  end
end
