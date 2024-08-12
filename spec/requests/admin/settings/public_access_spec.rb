RSpec.describe "Admin::Settings::PublicAccessController" do
  describe "GET :edit" do
    it "renders the edit page successfully" do
      get admin_settings_update_public_access_path

      expect(response).to have_http_status(:ok)
      expect(response.body)
        .to have_selector(".govuk-heading-xl", text: "Edit public access")
    end
  end

  describe "PATCH :update" do
    it "updates the public_access_enabled and downtime_type, then redirects to the settings page with valid params" do
      settings = create(:settings, public_access_enabled: false, downtime_type: :temporary)

      expect {
        patch admin_settings_update_public_access_path,
              params: { public_access_form: { enabled: "true", downtime_type: "permanent" } }
      }
        .to change(SettingsAudit, :count).by(1)

      expect(response).to redirect_to(admin_settings_path)
      expect(flash[:notice]).to eq("Public access updated")
      expect(settings.reload).to have_attributes(public_access_enabled: true, downtime_type: "permanent")
    end

    it "re-renders the edit page when given invalid params" do
      patch admin_settings_update_public_access_path,
            params: { public_access_form: { enabled: "true", downtime_type: "not-an-option" } }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to have_selector(".govuk-error-summary")
    end
  end
end
