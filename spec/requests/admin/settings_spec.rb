RSpec.describe "Admin::SettingsController" do
  describe "GET :show" do
    it "creates the settings singleton and renders the page successfully on first visit" do
      expect { get admin_settings_path }.to change(Settings, :count).by(1)
      expect(response).to have_http_status(:ok)
      expect(response.body).to have_selector(".govuk-heading-xl", text: "Settings")
    end

    it "renders the page successfully on subsequent visits" do
      create(:settings)
      expect { get admin_settings_path }.to not_change(Settings, :count)
      expect(response).to have_http_status(:ok)
      expect(response.body).to have_selector(".govuk-heading-xl", text: "Settings")
    end
  end
end
