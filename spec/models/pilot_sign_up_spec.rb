RSpec.describe PilotSignUp do
  let!(:settings) { create(:settings) }

  describe ".call" do
    let(:args) do
      {
        email: "email@test.com",
        user_description: "business_owner_or_self_employed",
        reason_for_visit: "find_specific_answer",
        found_chat: "search_engine",
        previous_sign_up_denied: false,
      }
    end

    it "raises an error when an early access user already exists for the email" do
      create(:early_access_user, email: "email@test.com")
      expect { described_class.call(**args) }.to raise_error(described_class::EarlyAccessUserConflictError)
    end

    it "raises an error when a waiting list user already exists for the email" do
      create(:waiting_list_user, email: "email@test.com")
      expect { described_class.call(**args) }.to raise_error(described_class::WaitingListUserConflictError)
    end

    context "when there are instant access places available" do
      before { allow(EarlyAccessAuthMailer).to receive(:access_granted).and_call_original }

      it "locks the settings instance and decrements the instant access places by 1" do
        allow(Settings).to receive(:instance).and_return(settings)
        expect(settings).to receive(:with_lock).and_call_original
        expect { described_class.call(**args) }.to change { settings.reload.instant_access_places }.by(-1)
      end

      it "creates an EarlyAccessUser with the correct attributes" do
        expect { described_class.call(**args) }.to change(EarlyAccessUser, :count).by(1)
        expect(EarlyAccessUser.last).to have_attributes(
          reason_for_visit: "find_specific_answer",
          email: "email@test.com",
          user_description: "business_owner_or_self_employed",
          found_chat: "search_engine",
          source: "instant_signup",
          previous_sign_up_denied: false,
        )
      end

      it "creates a session" do
        expect { described_class.call(**args) }.to change(Passwordless::Session, :count).by(1)
        expect(Passwordless::Session.last.authenticatable).to eq(EarlyAccessUser.last)
      end

      it "calls the mailer with the new session" do
        expect { described_class.call(**args) }.to change(EarlyAccessAuthMailer.deliveries, :count).by(1)
        created_session = Passwordless::Session.last
        expect(EarlyAccessAuthMailer).to have_received(:access_granted).with(created_session)
      end

      it "returns a result object with the correct attributes" do
        result = described_class.call(**args)
        expect(result)
          .to be_a(described_class::Result)
          .and have_attributes(
            outcome: :early_access_user,
            user: EarlyAccessUser.last,
            session: Passwordless::Session.last,
          )
      end
    end

    context "when there are no instant access places available" do
      before do
        allow(EarlyAccessAuthMailer).to receive(:waitlist).and_call_original
        Settings.instance.update!(instant_access_places: 0)
      end

      context "and there are waiting list places available" do
        it "creates a waiting list user with the correct attributes" do
          expect { described_class.call(**args) }.to change(WaitingListUser, :count).by(1)
          waiting_list_user = WaitingListUser.last
          expect(waiting_list_user)
            .to have_attributes(
              email: "email@test.com",
              user_description: "business_owner_or_self_employed",
              reason_for_visit: "find_specific_answer",
              found_chat: "search_engine",
              source: "insufficient_instant_places",
            )
        end

        it "sends a waiting list email to the user" do
          expect { described_class.call(**args) }.to change(EarlyAccessAuthMailer.deliveries, :count).by(1)
          expect(EarlyAccessAuthMailer).to have_received(:waitlist).with(WaitingListUser.last)
        end

        it "returns a result object with the correct attributes" do
          result = described_class.call(**args)
          expect(result)
            .to be_a(described_class::Result)
            .and have_attributes(
              outcome: :waiting_list_user,
              user: WaitingListUser.last,
              session: nil,
            )
        end
      end

      context "and there are no waiting list places available" do
        before do
          Settings.instance.update!(max_waiting_list_places: 0)
        end

        it "doesn't create a waiting list user" do
          expect { described_class.call(**args) }.not_to change(WaitingListUser, :count)
        end

        it "doesn't send a waiting list email" do
          expect { described_class.call(**args) }.not_to change(EarlyAccessAuthMailer.deliveries, :count)
        end

        it "returns a result object with the correct attributes" do
          result = described_class.call(**args)
          expect(result)
            .to be_a(described_class::Result)
            .and have_attributes(
              outcome: :waiting_list_full,
              user: nil,
              session: nil,
            )
        end
      end
    end
  end
end
