RSpec.describe "Admin::Settings::WaitingListPromotionsPerRunController" do
  describe "GET :edit" do
    it "renders the edit page successfully" do
      get admin_settings_edit_waiting_list_promotions_per_run_path

      expect(response).to have_http_status(:ok)
      expect(response.body)
        .to have_selector(".govuk-heading-xl", text: "Edit waiting list promotions per run")
    end
  end

  describe "PATCH :update" do
    it "updates the promotions per run and redirects to the settings page with valid params" do
      settings = create(:settings, waiting_list_promotions_per_run: 10)

      expect {
        patch admin_settings_edit_waiting_list_promotions_per_run_path,
              params: { waiting_list_promotions_per_run_form: { promotions_per_run: 15 } }
      }.to change(SettingsAudit, :count).by(1)
       .and change { settings.reload.waiting_list_promotions_per_run }.to(15)

      expect(response).to redirect_to(admin_settings_path)
      expect(flash[:notice]).to eq("Waiting list promotions per run updated")
    end

    it "re-renders the edit page when given invalid params" do
      patch admin_settings_edit_waiting_list_promotions_per_run_path,
            params: { waiting_list_promotions_per_run_form: { promotions_per_run: "" } }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to have_selector(".govuk-error-summary")
    end
  end
end
