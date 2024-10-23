RSpec.describe "Admin::Settings::MaxWaitingListPlacesController" do
  describe "GET :edit" do
    it "renders the edit page successfully" do
      get admin_settings_edit_max_waiting_list_places_path

      expect(response).to have_http_status(:ok)
      expect(response.body)
        .to have_selector(".govuk-heading-xl", text: "Edit maximum waiting list places")
    end
  end

  describe "PATCH :update" do
    it "updates the maximum waiting list places and redirects to the settings page with valid params" do
      settings = create(:settings, max_waiting_list_places: 10)

      expect {
        patch admin_settings_update_max_waiting_list_places_path,
              params: { max_waiting_list_places_form: { max_places: 15 } }
      }.to change(SettingsAudit, :count).by(1)
       .and change { settings.reload.max_waiting_list_places }.to(15)
      expect(response).to redirect_to(admin_settings_path)
      expect(flash[:notice]).to eq("Maximum waiting list places updated")
    end

    it "re-renders the edit page when given invalid params" do
      patch admin_settings_update_max_waiting_list_places_path,
            params: { max_waiting_list_places_form: { max_places: "" } }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to have_selector(".govuk-error-summary")
    end
  end
end
