RSpec.describe "ChatController" do
  describe "GET :index" do
    it "renders the initial onboarding page" do
      get chat_path

      expect(response).to have_http_status(:ok)
      expect(response.body)
        .to have_selector(".app-c-landing__title", text: "GOV.UK Chat")
    end

    it "sets the cache headers to 5 mins" do
      get chat_path

      expect(response.headers["Cache-Control"]).to eq("max-age=300, public")
    end
  end
end
