RSpec.describe "HomepageController" do
  describe "GET :index" do
    it "renders the welcome page" do
      get homepage_path

      expect(response).to have_http_status(:ok)
      expect(response.body)
        .to have_selector(".app-c-chat-introduction-title__title", text: "GOV.UK Chat")
    end

    it "sets the cache headers" do
      get homepage_path

      expect(response.headers["Cache-Control"]).to eq("max-age=60, public")
      expect(response.headers["Vary"]).to eq("Cookie")
    end
  end
end
