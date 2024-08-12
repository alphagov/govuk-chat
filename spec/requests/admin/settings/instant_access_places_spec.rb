RSpec.describe "Admin::Settings::InstantAccessPlacesController" do
  describe "GET :edit" do
    it "renders the edit page successfully" do
      get admin_edit_instant_access_places_path

      expect(response).to have_http_status(:ok)
      expect(response.body)
        .to have_selector(".govuk-heading-xl", text: "Edit instant access places")
    end
  end

  describe "PATCH :update" do
    it "updates the instant access places and redirects to the settings page with valid params" do
      settings = create(:settings, instant_access_places: 10)

      expect {
        patch admin_update_instant_access_places_path,
              params: { instant_access_places_form: { places: 5 } }
      }
        .to change(SettingsAudit, :count).by(1)
      expect(response).to redirect_to(admin_settings_path)
      expect(flash[:notice]).to eq("Instant access places updated")
      expect(settings.reload.instant_access_places).to eq(15)
    end

    it "re-renders the edit page when given invalid params" do
      patch admin_update_instant_access_places_path,
            params: { instant_access_places_form: { places: "" } }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to have_selector(".govuk-error-summary")
    end
  end
end
