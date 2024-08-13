RSpec.describe "Admin::Settings::SignUpEnabledController" do
  describe "GET :edit" do
    it "renders the edit page successfully" do
      get admin_settings_edit_sign_up_enabled_path

      expect(response).to have_http_status(:ok)
      expect(response.body)
        .to have_selector(".govuk-heading-xl", text: "Edit sign up enabled")
    end
  end

  describe "PATCH :update" do
    it "updates the sign up enabled attribute and redirects to the settings page with valid params" do
      settings = create(:settings, sign_up_enabled: false)

      expect {
        patch admin_settings_update_sign_up_enabled_path,
              params: { sign_up_enabled_form: { enabled: "true" } }
      }
        .to change(SettingsAudit, :count).by(1)
      expect(response).to redirect_to(admin_settings_path)
      expect(flash[:notice]).to eq("Sign up enabled updated")
      expect(settings.reload.sign_up_enabled).to be(true)
    end

    it "re-renders the edit page when given invalid params" do
      patch admin_settings_update_sign_up_enabled_path,
            params: { sign_up_enabled_form: { enabled: "true", author_comment: "s" * 256 } }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to have_selector(".govuk-error-summary")
    end
  end
end
