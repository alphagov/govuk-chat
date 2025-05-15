RSpec.describe Admin::Form::EarlyAccessUsers::CreateForm do
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

    it "returns false when the email already exists" do
      create(:early_access_user, email: "user@example.com")
      form = described_class.new(email: "user@example.com")

      expect(form).to be_invalid
      expect(form.errors.count).to eq(1)
      expect(form.errors.messages[:email]).to eq(["Email address already exists"])
    end
  end

  describe "#submit" do
    it "raises an error when the form object is invalid" do
      form = described_class.new
      expect { form.submit }.to raise_error(ActiveModel::ValidationError)
    end

    it "creates the user" do
      form = described_class.new(email: "foo@bar.com")

      expect { form.submit }
        .to change(EarlyAccessUser, :count).by(1)

      expect(EarlyAccessUser.last).to have_attributes(
        email: "foo@bar.com",
        source: "admin_added",
      )
    end

    it "returns the user" do
      form = described_class.new(email: "foo@bar.com")
      expect(form.submit).to eq(EarlyAccessUser.last)
    end

    it "creates a passwordless session and assigns the new user" do
      form = described_class.new(email: "foo@bar.com")

      expect { form.submit }
        .to change(Passwordless::Session, :count).by(1)

      expect(Passwordless::Session.last.authenticatable).to eq(EarlyAccessUser.last)
    end

    context "when a waiting list user exists for the email" do
      it "deletes the waiting list user" do
        user = create(:waiting_list_user, email: "foo@bar.com")

        form = described_class.new(email: "foo@bar.com")

        expect { form.submit }.to change(WaitingListUser, :count).by(-1)
        expect { user.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
end
