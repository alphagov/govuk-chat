RSpec.describe "OnboardingController" do
  describe "GET :limitations" do
    it "renders the limitations page" do
      get onboarding_limitations_path

      expect(response).to have_http_status(:ok)
      expect(response.body)
        .to have_selector(".gem-c-button", text: "I understand")
    end
  end

  describe "POST :limitations_confirm" do
    it "redirects to the privacy page" do
      post onboarding_limitations_confirm_path

      expect(response).to have_http_status(:redirect)
      expect(response).to redirect_to(onboarding_privacy_path)
    end

    it "sets session[:onboarding] to 'privacy'" do
      post onboarding_limitations_confirm_path
      expect(session[:onboarding]).to eq("privacy")
    end
  end

  describe "GET :privacy" do
    it "renders the privacy page" do
      get onboarding_privacy_path

      expect(response).to have_http_status(:ok)
      expect(response.body)
        .to have_selector(".gem-c-button", text: "Okay, start chatting")
    end
  end

  describe "POST :privacy_confirm" do
    it "sets the session[:onboarding] to 'conversation'" do
      post onboarding_privacy_confirm_path
      expect(session[:onboarding]).to eq("conversation")
    end

    context "when conversation_id is not set on the cookie" do
      it "redirects to the new conversation page" do
        post onboarding_privacy_confirm_path

        expect(response).to have_http_status(:redirect)
        expect(response).to redirect_to(new_conversation_path)
      end
    end

    context "when conversation_id is set on the cookie" do
      it "redirects to the conversation show page" do
        conversation = create(:conversation)
        cookies[:conversation_id] = conversation.id

        post onboarding_privacy_confirm_path

        expect(response).to have_http_status(:redirect)
        expect(response).to redirect_to(show_conversation_path(conversation))
      end
    end
  end
end
