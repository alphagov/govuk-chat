RSpec.describe "Admin::Settings::ApiAccessController" do
  it_behaves_like "limits access to users with the admin-area-settings permission",
                  routes: {
                    admin_settings_edit_api_access_path: %i[get patch],
                  }

  describe "GET :edit" do
    it "renders the edit page successfully" do
      get admin_settings_edit_api_access_path

      expect(response).to have_http_status(:ok)
      expect(response.body)
        .to have_selector(".govuk-heading-xl", text: "Edit API access")
    end
  end

  describe "PATCH :update" do
    it "updates the api_access_enabled, then redirects to the settings page" do
      settings = create(:settings, api_access_enabled: false)

      expect {
        patch admin_settings_edit_api_access_path,
              params: { api_access_form: { enabled: "true" } }
      }
        .to change(SettingsAudit, :count).by(1)

      expect(response).to redirect_to(admin_settings_path)
      expect(flash[:notice]).to eq("API access updated")
      expect(settings.reload).to have_attributes(api_access_enabled: true)
    end
  end
end
