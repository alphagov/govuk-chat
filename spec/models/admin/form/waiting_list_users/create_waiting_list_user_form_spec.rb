RSpec.describe Admin::Form::WaitingListUsers::CreateWaitingListUserForm do
  describe "validations" do
    it "returns false when the email is missing" do
      form = described_class.new

      expect(form).to be_invalid
      expect(form.errors.count).to eq(1)
      expect(form.errors.messages[:email]).to eq(["Enter an email address"])
    end

    it "returns false when the email is invalid" do
      form = described_class.new(email: "test")

      expect(form).to be_invalid
      expect(form.errors.count).to eq(1)
      expect(form.errors.messages[:email]).to eq(["Enter a valid email address"])
    end

    it "returns false if there is already a waiting list user with the same email" do
      create(:waiting_list_user, email: "foo@bar.com")

      form = described_class.new(email: "foo@bar.com")

      expect(form).to be_invalid
      expect(form.errors.count).to eq(1)
      expect(form.errors.messages[:email]).to eq(["There is already a pilot user with this email address"])
    end

    it "returns false if there is already an early access user with the same email" do
      create(:early_access_user, email: "foo@bar.com")

      form = described_class.new(email: "foo@bar.com")

      expect(form).to be_invalid
      expect(form.errors.count).to eq(1)
      expect(form.errors.messages[:email]).to eq(["There is already a pilot user with this email address"])
    end
  end

  describe "#submit" do
    it "raises an error when the form object is invalid" do
      form = described_class.new
      expect { form.submit }.to raise_error(ActiveModel::ValidationError)
    end

    it "creates the user" do
      form = described_class.new(
        email: "foo@bar.com",
        user_description: :business_owner_or_self_employed,
        reason_for_visit: :find_specific_answer,
      )

      expect { form.submit }
        .to change(WaitingListUser, :count).by(1)

      expect(WaitingListUser.last).to have_attributes(
        email: "foo@bar.com",
        user_description: "business_owner_or_self_employed",
        reason_for_visit: "find_specific_answer",
        source: "admin_added",
      )
    end

    it "returns the user" do
      form = described_class.new(email: "foo@bar.com")
      expect(form.submit).to eq(WaitingListUser.last)
    end
  end
end
