RSpec.describe "ChatController" do
  describe "GET :index" do
    it "renders the initial onboarding page" do
      get chat_path

      expect(response).to have_http_status(:ok)
      expect(response.body)
        .to have_selector(".gem-c-title__text", text: "Welcome to GOV.UK Chat")
    end

    it "sets the cache headers to 5 mins" do
      get chat_path

      expect(response.headers["Cache-Control"]).to eq("max-age=300, public")
    end
  end

  describe "GET :onboarding_limitations" do
    it "renders the onboarding limitations page" do
      get onboarding_limitations_path

      expect(response).to have_http_status(:ok)
      expect(response.body)
        .to have_selector(".gem-c-button", text: "I understand")
    end
  end

  describe "POST :onboarding_limitations_confirm" do
    it "redirects to the onboarding privacy page" do
      post onboarding_limitations_confirm_path

      expect(response).to have_http_status(:redirect)
      expect(response).to redirect_to(onboarding_privacy_path)
    end

    it "sets session[:onboarding] to 'privacy'" do
      post onboarding_limitations_confirm_path
      expect(session[:onboarding]).to eq("privacy")
    end
  end

  describe "GET :onboarding_privacy" do
    it "renders the onboarding privacy page" do
      get onboarding_privacy_path

      expect(response).to have_http_status(:ok)
      expect(response.body)
        .to have_selector(".gem-c-button", text: "Okay, start chatting")
    end
  end

  describe "POST :onboarding_privacy_confirm" do
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
