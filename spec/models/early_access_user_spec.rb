RSpec.describe EarlyAccessUser do
  describe ".promote_waiting_list_user" do
    it "creates the early access user and deletes the waiting list user" do
      waiting_list_user = create(:waiting_list_user)

      described_class.promote_waiting_list_user(waiting_list_user)

      expect(WaitingListUser.find_by_id(waiting_list_user.id)).to be_nil

      early_access_user = described_class.find_by_email(waiting_list_user.email)

      expect(early_access_user).to have_attributes(
        email: waiting_list_user.email,
        user_description: waiting_list_user.user_description,
        reason_for_visit: waiting_list_user.reason_for_visit,
        source: "admin_promoted",
      )
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
end
