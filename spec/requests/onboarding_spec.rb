RSpec.describe "OnboardingController" do
  it_behaves_like "handles a user accessing onboarding when onboarded",
                  routes: {
                    onboarding_limitations_path: %i[get],
                    onboarding_limitations_confirm_path: %i[post],
                    onboarding_privacy_path: %i[get],
                    onboarding_privacy_confirm_path: %i[post],
                  }
  it_behaves_like "handles a user accessing onboarding limitations once completed",
                  routes: { onboarding_limitations_path: %i[get], onboarding_limitations_confirm_path: %i[post] }
  it_behaves_like "handles a user accessing onboarding privacy when onboarding isn't started",
                  routes: { onboarding_privacy_path: %i[get], onboarding_privacy_confirm_path: %i[post] }

  describe "GET :limitations" do
    it "renders the limitations page" do
      get onboarding_limitations_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to have_content(/Hello 👋 I’m GOV.UK Chat/)
      expect(response.body).to have_button("Tell me more", name: "more_information", value: "true")
    end

    context "when session[:more_information] is true" do
      before do
        post onboarding_limitations_confirm_path(more_information: true)
      end

      it "renders the tell me more information" do
        get onboarding_limitations_path
        expect(response.body).to have_content "Tell me more"
        expect(response.body).to have_content "I combine the same technology used on ChatGPT with GOV.UK guidance."
        expect(response.body).to have_selector(".govuk-link", text: "Take me to GOV.UK")
      end
    end

    context "when the request format is JSON" do
      context "when session[:more_information] is true" do
        before do
          post onboarding_limitations_confirm_path(more_information: true)
        end

        it "returns a successful response with the correct JSON" do
          get onboarding_limitations_path, params: { format: :json }

          expect(response).to have_http_status(:ok)
          expect(JSON.parse(response.body)).to match({
            "title" => "More information on GOV.UK Chat and its limitations",
            "conversation_data" => { "module" => "onboarding" },
            "conversation_append_html" => /I combine the same technology used on ChatGPT with GOV.UK guidance./,
            "form_html" => /Take me to GOV.UK/,
          })
        end
      end

      context "when session[:more_information] is not set" do
        it "returns a not_acceptable response" do
          get onboarding_limitations_path, params: { format: :json }

          expect(response).to have_http_status(:not_acceptable)
          expect(JSON.parse(response.body)).to eq({})
        end
      end
    end
  end

  describe "POST :limitations_confirm" do
    it "redirects to the privacy page" do
      post onboarding_limitations_confirm_path

      expect(response).to have_http_status(:redirect)
      expect(response).to redirect_to(onboarding_privacy_path(anchor: "i-understand"))
    end

    it "sets session[:onboarding] to 'privacy'" do
      post onboarding_limitations_confirm_path
      expect(session[:onboarding]).to eq("privacy")
    end

    context "when the more_information param is present" do
      it "sets session[:more_information] to true" do
        post onboarding_limitations_confirm_path(more_information: true)
        expect(session[:more_information]).to be(true)
      end

      it "redirects to the limitations page" do
        post onboarding_limitations_confirm_path(more_information: true)
        expect(response).to redirect_to(onboarding_limitations_path(anchor: "tell-me-more"))
      end
    end
  end

  describe "GET :privacy" do
    include_context "with onboarding limitations completed"

    it "renders the privacy page" do
      get onboarding_privacy_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to have_content(/You can always find information about my limitations in about GOV.UK Chat/)
      expect(response.body).to have_selector(".app-c-blue-button", text: "Okay, start chatting")
    end

    context "when the request format is JSON" do
      it "returns the the correct JSON" do
        get onboarding_privacy_path, params: { format: :json }

        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)).to match({
          "title" => "Privacy on GOV.UK Chat",
          "conversation_data" => { "module" => "onboarding" },
          "conversation_append_html" => /You can always find information about my limitations in.*about GOV.UK Chat/,
          "form_html" => /Okay, start chatting/,
        })
      end
    end
  end

  describe "POST :privacy_confirm" do
    include_context "with onboarding limitations completed"

    it "sets the session[:onboarding] to 'conversation'" do
      post onboarding_privacy_confirm_path
      expect(session[:onboarding]).to eq("conversation")
    end

    it "redirects to the show conversation page" do
      post onboarding_privacy_confirm_path

      expect(response).to have_http_status(:redirect)
      expect(response).to redirect_to(show_conversation_path(anchor: "start-chatting"))
    end
  end
end
