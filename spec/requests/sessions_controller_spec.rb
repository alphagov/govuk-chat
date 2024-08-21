RSpec.describe "sessions controller" do
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

      it "locks the Password::Session resource to prevent concurrent login activity" do
        allow(Passwordless::Session).to receive(:lock).and_call_original
        get magic_link
        expect(Passwordless::Session).to have_received(:lock)
      end

      context "with a stored redirect location" do
        it "redirects to the stored location" do
          get show_conversation_path
          follow_redirect!
          get magic_link
          expect(response).to redirect_to(show_conversation_path)
        end
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
          expect(response).to redirect_to(early_access_entry_sign_in_or_up_path)
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
        expect(response.body).to include("This link has expired or been used already")
      end
    end

    context "when the magic link has been used" do
      let(:passwordless_session) { create :passwordless_session, :claimed }

      it "disallows access" do
        get magic_link
        expect(response).to have_http_status(:conflict)
        expect(response.body).to include("This link has expired or been used already")
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
        expect(response.body).to include("This link has expired or been used already")
      end
    end

    context "when the token doesn't match" do
      let(:passwordless_session) { create :passwordless_session }

      it "disallows access" do
        get magic_link_path(passwordless_session.to_param, "the-wrong-token")
        expect(response).to have_http_status(:not_found)
        expect(response.body).to include("This link has expired or been used already")
      end
    end
  end

  describe "GET :destroy" do
    before { sign_in_early_access_user(create(:early_access_user)) }

    it "redirects the user to early access entry point" do
      get sign_out_path
      expect(response).to redirect_to(early_access_entry_sign_in_or_up_path)
    end

    it "signs out the user" do
      get onboarding_limitations_path
      expect(response).to have_http_status(:ok)

      get sign_out_path

      get onboarding_limitations_path
      expect(response).to redirect_to(early_access_entry_sign_in_or_up_path)
    end
  end
end
