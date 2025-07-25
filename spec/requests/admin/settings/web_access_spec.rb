RSpec.describe "Admin::Settings::WebAccessController" do
  it_behaves_like "limits access to users with the admin-area-settings permission",
                  routes: {
                    admin_settings_edit_web_access_path: %i[get patch],
                  }

  describe "GET :edit" do
    it "renders the edit page successfully" do
      get admin_settings_edit_web_access_path

      expect(response).to have_http_status(:ok)
      expect(response.body)
        .to have_selector(".govuk-heading-xl", text: "Edit web access")
    end
  end

  describe "PATCH :update" do
    it "updates the web_access_enabled then redirects to the settings page" do
      settings = create(:settings, web_access_enabled: false)

      expect {
        patch admin_settings_edit_web_access_path,
              params: { web_access_form: { enabled: "true" } }
      }
        .to change(SettingsAudit, :count).by(1)

      expect(response).to redirect_to(admin_settings_path)
      expect(flash[:notice]).to eq("Web access updated")
      expect(settings.reload).to have_attributes(web_access_enabled: true)
    end

    it "re-renders the edit page when given invalid params" do
      patch admin_settings_edit_web_access_path,
            params: { web_access_form: { enabled: "true", author_comment: "a" * 256 } }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to have_selector(".govuk-error-summary")
    end
  end
end
