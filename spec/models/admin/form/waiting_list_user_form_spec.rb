RSpec.describe Admin::Form::WaitingListUserForm do
  let(:valid_attributes) do
    {
      email: "user@example.com",
      user_description: "business_owner_or_self_employed",
      reason_for_visit: "find_specific_answer",
      found_chat: "search_engine",
    }
  end

  describe "validations" do
    it "returns false when the email is missing" do
      form = described_class.new(valid_attributes.except(:email))

      expect(form).to be_invalid
      expect(form.errors.count).to eq(1)
      expect(form.errors.messages[:email]).to eq(["Enter an email address"])
    end

    it "returns false when the email is invalid" do
      form = described_class.new(valid_attributes.merge(email: "test"))

      expect(form).to be_invalid
      expect(form.errors.count).to eq(1)
      expect(form.errors.messages[:email]).to eq(["Enter a valid email address"])
    end

    it "returns false if there is already a waiting list user with the same email" do
      user = create(:waiting_list_user, email: "user@example.com")

      form = described_class.new(valid_attributes.merge(email: user.email))

      expect(form).to be_invalid
      expect(form.errors.count).to eq(1)
      expect(form.errors.messages[:email]).to eq(["There is already a waiting list user with this email address"])
    end

    it "returns false if there is already an early access user with the same email" do
      user = create(:early_access_user, email: "user@example.com")

      form = described_class.new(valid_attributes.merge(email: user.email))

      expect(form).to be_invalid
      expect(form.errors.count).to eq(1)
      expect(form.errors.messages[:email]).to eq(["There is already an early access user with this email address"])
    end

    it "returns false if the user_description is invalid" do
      form = described_class.new(valid_attributes.merge(user_description: "invalid"))

      expect(form).to be_invalid
      expect(form.errors.count).to eq(1)
      expect(form.errors.messages[:user_description]).to eq(["Invalid User description option selected"])
    end

    it "returns false if the reason_for_visit is invalid" do
      form = described_class.new(valid_attributes.merge(reason_for_visit: "invalid"))

      expect(form).to be_invalid
      expect(form.errors.count).to eq(1)
      expect(form.errors.messages[:reason_for_visit]).to eq(["Invalid Reason for visit option selected"])
    end

    it "returns false if the found_chat is invalid" do
      form = described_class.new(valid_attributes.merge(found_chat: "invalid"))

      expect(form).to be_invalid
      expect(form.errors.count).to eq(1)
      expect(form.errors.messages[:found_chat]).to eq(["Invalid Found chat option selected"])
    end

    it "allows nil values for reason_for_visit and user_description" do
      form = described_class.new(valid_attributes.merge(reason_for_visit: nil, user_description: nil))

      expect(form).to be_valid
    end
  end

  describe "#submit" do
    it "raises an error when the form object is invalid" do
      form = described_class.new
      expect { form.submit }.to raise_error(ActiveModel::ValidationError)
    end

    context "when creating a user" do
      it "creates the user" do
        form = described_class.new(valid_attributes)

        expect { form.submit }
          .to change(WaitingListUser, :count).by(1)

        expect(WaitingListUser.last).to have_attributes(
          email: "user@example.com",
          user_description: "business_owner_or_self_employed",
          reason_for_visit: "find_specific_answer",
          found_chat: "search_engine",
          source: "admin_added",
        )
      end

      it "returns the user" do
        form = described_class.new(valid_attributes)
        expect(form.submit).to eq(WaitingListUser.last)
      end
    end

    context "when updating an existing user" do
      let(:user) do
        create(
          :waiting_list_user,
          email: "user@example.com",
          user_description: "business_advisor",
          reason_for_visit: "research_topic",
          found_chat: "govuk_website",
        )
      end

      it "updates the user" do
        form = described_class.new(valid_attributes.merge(user:, email: "newemail@bar.com"))

        expect { form.submit }
          .to change(user, :email).to("newemail@bar.com")
          .and change(user, :user_description).to("business_owner_or_self_employed")
          .and change(user, :reason_for_visit).to("find_specific_answer")
          .and change(user, :found_chat).to("search_engine")
      end

      it "does not require the email attribute" do
        form = described_class.new(user:, user_description: "business_owner_or_self_employed")

        form.submit

        expect(user.reload).to have_attributes(
          email: "user@example.com",
          user_description: "business_owner_or_self_employed",
        )
      end

      it "returns the user" do
        form = described_class.new(valid_attributes.merge(user:))

        returned_user = form.submit
        expect(returned_user.id).to eq(user.id)
      end
    end
  end
end
