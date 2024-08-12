RSpec.describe "Admin::Settings::DelayedAccessPlacesController" do
  describe "GET :edit" do
    it "renders the edit page successfully" do
      get admin_edit_delayed_access_places_path

      expect(response).to have_http_status(:ok)
      expect(response.body)
        .to have_selector(".govuk-heading-xl", text: "Edit delayed access places")
    end
  end

  describe "PATCH :update" do
    it "updates the delayed access places and redirects to the settings page with valid params" do
      settings = create(:settings, delayed_access_places: 10)

      expect {
        patch admin_update_delayed_access_places_path,
              params: { delayed_access_places_form: { places: 5 } }
      }
        .to change(SettingsAudit, :count).by(1)
      expect(response).to redirect_to(admin_settings_path)
      expect(flash[:notice]).to eq("Delayed access places updated")
      expect(settings.reload.delayed_access_places).to eq(15)
    end

    it "re-renders the edit page when given invalid params" do
      patch admin_update_delayed_access_places_path,
            params: { delayed_access_places_form: { places: "" } }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to have_selector(".govuk-error-summary")
    end
  end
end
