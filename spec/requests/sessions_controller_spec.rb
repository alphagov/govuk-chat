RSpec.describe "sessions controller" do
  it_behaves_like "throttles traffic from a single IP address",
                  routes: { magic_link_path: %i[get] }, limit: 20, period: 5.minutes do
                    let(:route_params) { { id: SecureRandom.uuid, token: SecureRandom.uuid } }
                  end

  describe "HEAD :confirm" do
    let(:passwordless_session) { create :passwordless_session }
    let(:magic_link) { magic_link_url(passwordless_session.to_param, passwordless_session.token) }

    # some mail clients make this request to check a link is safe
    it "returns head: OK" do
      head magic_link
      expect(response).to have_http_status(:ok)
      expect(response.body).to be_empty
    end

    # We don't want to sign-in the user in this situation
    it "does nothing else" do
      allow(Passwordless::Session).to receive(:lock)
      head magic_link
      expect(Passwordless::Session).not_to have_received(:lock)
    end
  end

  describe "GET :confirm" do
    let(:magic_link) { magic_link_url(passwordless_session.to_param, passwordless_session.token) }

    context "with a valid magic link" do
      let(:passwordless_session) { create :passwordless_session }

      it "allows access" do
        get magic_link
        expect(response).to redirect_to(onboarding_limitations_path)
      end

      it "can artificially slow down requests with Bcrypt" do
        allow(Passwordless.config).to receive(:combat_brute_force_attacks).and_return(true)
        allow(BCrypt::Password).to receive(:create).and_call_original

        get magic_link

        expect(BCrypt::Password).to have_received(:create).with(passwordless_session.token)
      end

      it "locks the Password::Session resource to prevent concurrent login activity" do
        allow(Passwordless::Session).to receive(:lock).and_call_original
        get magic_link
        expect(Passwordless::Session).to have_received(:lock)
      end

      context "and the user has had access revoked" do
        before { passwordless_session.authenticatable.touch(:revoked_at) }

        it "disallows access" do
          get magic_link
          expect(response).to have_http_status(:forbidden)
          expect(response.body).to include("You do not have access to this page")
        end

        it "doesn't sign a user in" do
          get magic_link
          get show_conversation_path
          expect(response).to redirect_to(homepage_path)
        end
      end

      it "deletes the conversation_id cookie if present" do
        cookies[:conversation_id] = "123"
        get magic_link
        expect(cookies[:conversation_id]).to be_blank
      end

      context "when the user has an active conversation" do
        let(:passwordless_session) { create :passwordless_session }
        let!(:conversation) do
          create(:conversation, :not_expired, user: passwordless_session.authenticatable)
        end

        it "sets the conversation_id cookie to the most recent active conversations id" do
          create(:conversation, :not_expired, user: passwordless_session.authenticatable, created_at: 1.day.ago)
          get magic_link
          expect(cookies[:conversation_id]).to eq conversation.id
        end

        it "renders a page prompting a user to choose whether to continue their last chat" do
          get magic_link
          expect(response).to have_http_status(:ok)
          expect(response.body).to include("Do you want to continue your last chat?")
        end
      end

      context "when the user has completed onboarding" do
        it "sets session[:onboarding] to 'conversation'" do
          passwordless_session.authenticatable.update!(onboarding_completed: true)
          get magic_link
          expect(session[:onboarding]).to eq "conversation"
        end
      end
    end

    context "when a user is already signed in" do
      let(:passwordless_session) { create :passwordless_session }

      before { sign_in_early_access_user(passwordless_session.authenticatable) }

      it "redirects the user to their conversation" do
        get magic_link
        expect(response).to redirect_to(show_conversation_path)
      end
    end

    context "with a timed out magic link" do
      let(:passwordless_session) { create :passwordless_session, :timed_out }

      it "shows session timeout page" do
        get magic_link
        expect(response).to have_http_status(:gone)
        expect(response.body).to include("There is a problem with your link")
      end
    end

    context "when the magic link has been used" do
      let(:passwordless_session) { create :passwordless_session, :claimed }

      it "disallows access" do
        get magic_link
        expect(response).to have_http_status(:conflict)
        expect(response.body).to include("There is a problem with your link")
      end
    end

    context "when the session doesn't exist" do
      let!(:passwordless_session) { create :passwordless_session }

      before do
        passwordless_session.destroy
      end

      it "disallows access" do
        get magic_link
        expect(response).to have_http_status(:not_found)
        expect(response.body).to include("There is a problem with your link")
      end
    end

    context "when the token doesn't match" do
      let(:passwordless_session) { create :passwordless_session }

      it "disallows access" do
        get magic_link_path(passwordless_session.to_param, "the-wrong-token")
        expect(response).to have_http_status(:not_found)
        expect(response.body).to include("There is a problem with your link")
      end
    end

    context "when the early access user has been deleted" do
      let(:passwordless_session) { create :passwordless_session }

      before { passwordless_session.authenticatable.destroy! }

      it "disallows access" do
        get magic_link
        expect(response).to have_http_status(:not_found)
        expect(response.body).to include("There is a problem with your link")
      end
    end
  end

  describe "GET :destroy" do
    it "signs out the user" do
      sign_in_early_access_user(create(:early_access_user))

      get onboarding_limitations_path

      expect(response).to have_http_status(:ok)

      get sign_out_path

      get onboarding_limitations_path
      expect(response).to redirect_to(homepage_path)
    end

    it "renders a signed out page" do
      sign_in_early_access_user(create(:early_access_user))

      get sign_out_path

      expect(response.body).to have_content("You are now signed out")
    end

    it "renders for a signed-out user" do
      get sign_out_path

      expect(response.body).to have_content("You are now signed out")
    end
  end
end
