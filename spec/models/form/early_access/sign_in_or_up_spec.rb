RSpec.describe Form::EarlyAccess::SignInOrUp do
  describe "validations" do
    it "is invalid without an email address" do
      form = described_class.new(email: nil)
      expect(form).to be_invalid
      expect(form.errors.messages[:email])
        .to eq([described_class::EMAIL_ADDRESS_PRESENCE_ERROR_MESSAGE])
    end

    it "is invalid if email is more than 512 characters" do
      form = described_class.new(email: "#{'a' * 512}@example.com")
      expect(form).to be_invalid
      expect(form.errors.messages[:email])
        .to eq([sprintf(described_class::EMAIL_ADDRESS_LENGTH_ERROR_MESSAGE, count: 512)])
    end

    it "is invalid if email address is not a valid email" do
      form = described_class.new(email: "non.existent.email")
      expect(form).to be_invalid
      expect(form.errors.messages[:email])
        .to eq([described_class::EMAIL_ADDRESS_FORMAT_ERROR_MESSAGE])
    end
  end

  describe "#submit" do
    before do
      allow(EarlyAccessAuthMailer).to receive(:access_granted).and_call_original
    end

    it "raises an error when the form object is invalid" do
      form = described_class.new(email: "")
      expect { form.submit }.to raise_error(ActiveModel::ValidationError)
    end

    context "when the user doesn't have an early access account" do
      let(:form) do
        described_class.new(email: "non.existent.email@example.com")
      end

      it "returns a result object with the correct attributes" do
        result = form.submit
        expect(result)
          .to be_a(described_class::Result)
          .and have_attributes(
            outcome: :new_user,
            email: form.email,
            user: nil,
          )
      end
    end

    context "when the user has an early access account" do
      let(:user) { create :early_access_user, email: "existing.email@example.com" }
      let(:form) { described_class.new(email: user.email) }

      it "creates a session" do
        expect { form.submit }.to change(Passwordless::Session, :count).by(1)
      end

      it "assigns the early access user" do
        form.submit
        expect(Passwordless::Session.last.authenticatable).to eq(EarlyAccessUser.last)
      end

      it "calls the mailer with the new session" do
        expect { form.submit }.to change(EarlyAccessAuthMailer.deliveries, :count).by(1)
        created_session = Passwordless::Session.last
        expect(EarlyAccessAuthMailer).to have_received(:access_granted).with(created_session)
      end

      it "returns a Result instance with the correct attributes" do
        result = form.submit
        expect(result)
          .to be_a(described_class::Result)
          .and have_attributes(
            outcome: :existing_early_access_user,
            email: user.email,
            user:,
          )
      end
    end

    context "when the user has a waiting list account" do
      let(:user) { create(:waiting_list_user, email: "existing.email@example.com") }
      let(:form) { described_class.new(email: user.email) }

      it "returns a Result instance with the correct attributes" do
        result = form.submit
        expect(result)
          .to be_a(described_class::Result)
          .and have_attributes(
            outcome: :existing_waiting_list_user,
            email: user.email,
            user:,
          )
      end
    end

    context "when the user has an account that has been revoked" do
      let(:user) { create :early_access_user, :revoked }
      let(:form) { described_class.new(email: user.email) }

      it "returns a result object with the correct attributes" do
        result = form.submit
        expect(result)
          .to be_a(described_class::Result)
          .and have_attributes(
            outcome: :user_revoked,
            email: user.email,
            user:,
          )
      end
    end
  end
end
