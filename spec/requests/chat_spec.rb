RSpec.describe "ChatController" do
  describe "GET :index" do
    context "when early access authentication is enabled" do
      before do
        allow(Rails.configuration).to receive(:available_without_early_access_authentication).and_return(false)
      end

      it "renders the early access authentication welcome page" do
        get chat_path

        expect(response).to have_http_status(:ok)
        expect(response.body)
          .to have_content(:all, "Early Access")
          .and have_selector(".app-c-chat-introduction__title", text: "GOV.UK Chat")
      end
    end

    context "when early access authentication is disabled" do
      before do
        allow(Rails.configuration).to receive(:available_without_early_access_authentication).and_return(false)
      end

      it "renders the welcome page" do
        get chat_path

        expect(response).to have_http_status(:ok)
        expect(response.body)
          .to have_selector(".app-c-chat-introduction__title", text: "GOV.UK Chat")
      end
    end

    it "sets the cache headers to 5 mins" do
      get chat_path

      expect(response.headers["Cache-Control"]).to eq("max-age=300, public")
    end

    it "skips regenerating session so the resource can be cached" do
      # create a session
      get show_conversation_path
      expect(response.cookies.keys).to include("_govuk_chat_session")

      get chat_path
      expect(response.cookies).to be_empty
    end
  end
end
