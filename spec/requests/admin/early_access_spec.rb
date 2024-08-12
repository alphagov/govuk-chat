RSpec.describe "Admin::EarlyAccessController" do
  describe "GET :index" do
    it "renders the page successfully" do
      get admin_early_access_users_path

      expect(response).to have_http_status(:ok)
    end
  end
end
