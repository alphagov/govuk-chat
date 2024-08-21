RSpec.describe Form::EarlyAccess::ReasonForVisit do
  let!(:settings) { create(:settings) }

  describe "validations" do
    it "is valid with a choice" do
      form = described_class.new(choice: "find_specific_answer")
      expect(form).to be_valid
    end

    it "is invalid without a choice" do
      form = described_class.new(choice: "")
      expect(form).to be_invalid
      expect(form.errors.messages[:choice])
        .to eq([described_class::CHOICE_PRESENCE_ERROR_MESSAGE])
    end
  end

  describe "#submit" do
    let(:form) do
      described_class.new(
        choice: "find_specific_answer",
        email: "email@test.com",
        user_description: "business_owner_or_self_employed",
      )
    end

    it "raises an error when the form object is invalid" do
      form = described_class.new(choice: "")
      expect { form.submit }.to raise_error(ActiveModel::ValidationError)
    end

    it "raises an error when an early access user already exists for the email" do
      create(:early_access_user, email: "email@test.com")
      expect { form.submit }.to raise_error(described_class::EarlyAccessUserConflictError)
    end

    it "raises an error when a waiting list user already exists for the email" do
      create(:waiting_list_user, email: "email@test.com")
      expect { form.submit }.to raise_error(described_class::WaitingListUserConflictError)
    end

    context "when there are instant access places available" do
      before { allow(EarlyAccessAuthMailer).to receive(:sign_in).and_call_original }

      it "locks the settings instance and decrements the instant access places by 1" do
        allow(Settings).to receive(:instance).and_return(settings)
        expect(settings).to receive(:with_lock).and_call_original
        expect { form.submit }.to change { settings.reload.instant_access_places }.by(-1)
      end

      it "creates an EarlyAccessUser with the correct attributes" do
        expect { form.submit }.to change(EarlyAccessUser, :count).by(1)
        expect(EarlyAccessUser.last).to have_attributes(
          reason_for_visit: "find_specific_answer",
          email: "email@test.com",
          user_description: "business_owner_or_self_employed",
          source: "instant_signup",
        )
      end

      it "creates a session" do
        expect { form.submit }.to change(Passwordless::Session, :count).by(1)
      end

      it "assigns the early access user to the session" do
        form.submit
        expect(Passwordless::Session.last.authenticatable).to eq(EarlyAccessUser.last)
      end

      it "calls the mailer with the new session" do
        expect { form.submit }.to change(EarlyAccessAuthMailer.deliveries, :count).by(1)
        created_session = Passwordless::Session.last
        expect(EarlyAccessAuthMailer).to have_received(:sign_in).with(created_session)
      end

      it "returns a result object with the correct attributes" do
        result = form.submit
        expect(result)
          .to be_a(Form::EarlyAccess::ReasonForVisit::Result)
          .and have_attributes(
            outcome: :early_access_user,
            user: EarlyAccessUser.last,
          )
      end
    end

    context "when there are no instant access places available" do
      before do
        allow(EarlyAccessAuthMailer).to receive(:waitlist).and_call_original
        Settings.instance.update!(instant_access_places: 0)
      end

      it "creates a waiting list user with the correct attributes" do
        expect { form.submit }.to change(WaitingListUser, :count).by(1)
        waiting_list_user = WaitingListUser.last
        expect(waiting_list_user)
          .to have_attributes(
            email: "email@test.com",
            user_description: "business_owner_or_self_employed",
            reason_for_visit: "find_specific_answer",
            source: "insufficient_instant_places",
          )
      end

      it "sends a waiting list email to the user" do
        expect { form.submit }.to change(EarlyAccessAuthMailer.deliveries, :count).by(1)
        expect(EarlyAccessAuthMailer).to have_received(:waitlist).with(WaitingListUser.last)
      end

      it "returns a result object with the correct attributes" do
        result = form.submit
        expect(result)
          .to be_a(Form::EarlyAccess::ReasonForVisit::Result)
          .and have_attributes(
            outcome: :waiting_list_user,
            user: WaitingListUser.last,
          )
      end
    end
  end
end
