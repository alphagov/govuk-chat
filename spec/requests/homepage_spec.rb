RSpec.describe "HomepageController" do
  describe "GET :index" do
    it "renders the welcome page" do
      get homepage_path

      expect(response).to have_http_status(:ok)
      expect(response.body)
        .to have_selector(".app-c-chat-introduction-title__title", text: "Try GOV.UK Chat")
    end
  end
end
