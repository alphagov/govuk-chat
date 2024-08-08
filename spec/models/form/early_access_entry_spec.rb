RSpec.describe Form::EarlyAccessEntry do
  describe "#submit" do
    let(:user) { create :early_access_user }
    let(:form) { described_class.new(email: user.email) }

    before do
      allow(EarlyAccessAuthMailer).to receive(:sign_in).and_call_original
    end

    context "when the user exists" do
      it "creates a session" do
        expect { form.submit }.to change(Passwordless::Session, :count).by(1)
      end

      it "assigns the early access user" do
        form.submit
        expect(Passwordless::Session.last.authenticatable).to eq(user)
      end

      it "calls the mailer with the new session" do
        expect { form.submit }.to change(EarlyAccessAuthMailer.deliveries, :count).by(1)
        created_session = Passwordless::Session.last
        expect(EarlyAccessAuthMailer).to have_received(:sign_in).with(created_session)
      end
    end

    ## TODO this will change - we will be asking some questions as eligibility check
    context "with a new user" do
      it "creates a session and early access user" do
        expect { form.submit }.to change(Passwordless::Session, :count).by(1)
                              .and change(EarlyAccessUser, :count).by(1)
      end

      it "assigns the early access user" do
        form.submit
        expect(Passwordless::Session.last.authenticatable).to eq(user)
      end

      it "calls the mailer with the new session" do
        expect { form.submit }.to change(EarlyAccessAuthMailer.deliveries, :count).by(1)
        created_session = Passwordless::Session.last
        expect(EarlyAccessAuthMailer).to have_received(:sign_in).with(created_session)
      end
    end
  end
end
