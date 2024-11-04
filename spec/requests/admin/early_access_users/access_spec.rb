RSpec.describe "Admin::EarlyAccessUsers::AccessController" do
  describe "GET :revoke" do
    it "renders the revoke access form" do
      user = create(:early_access_user)
      get revoke_admin_early_access_user_path(user)

      expect(response.body)
        .to have_content("Reason for revoking access")
        .and have_selector("textarea#revoke-reason")
    end

    it "redirects to the user's page if the user's access is already revoked" do
      user = create(:early_access_user, :revoked)
      get revoke_admin_early_access_user_path(user)
      expect(response).to redirect_to(admin_early_access_user_path(user))
    end
  end

  describe "PATCH :revoke_confirm" do
    let(:user) { create(:early_access_user) }

    it "updates the user's revoked attributes and redirects to the user's page" do
      expect {
        patch(
          revoke_admin_early_access_user_path(user),
          params: {
            access_form: { revoke_reason: "Asking too many questions" },
          },
        )
      }
      .to change { user.reload.revoked_reason }.to("Asking too many questions")

      expect(response).to redirect_to(admin_early_access_user_path(user))
      expect(flash[:notice]).to eq("Access revoked")
    end

    it "re-renders the edit page when given invalid params" do
      patch(
        revoke_admin_early_access_user_path(user),
        params: { access_form: { revoke_reason: "" } },
      )

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to have_selector(".govuk-error-summary")
    end

    it "redirects to the user's page if the user's access is already revoked" do
      user = create(:early_access_user, :revoked)
      patch revoke_admin_early_access_user_path(user)
      expect(response).to redirect_to(admin_early_access_user_path(user))
    end
  end

  describe "GET :restore" do
    it "renders the page successfully" do
      user = create(:early_access_user, :shadow_banned)
      get restore_admin_early_access_user_path(user)

      expect(response).to have_http_status(:ok)
      expect(response.body).to have_content("Reason for restoring access")
    end

    it "redirects to the user's page if the user's is not shadow banned or had their access revoked" do
      user = create(:early_access_user)
      patch restore_admin_early_access_user_path(user)
      expect(response).to redirect_to(admin_early_access_user_path(user))
    end
  end

  describe "PATCH :restore" do
    it "updates the user's revoked attributes and redirects to the user's page" do
      user = create(:early_access_user, :revoked, bannable_action_count: 1)

      expect {
        patch(
          restore_admin_early_access_user_path(user),
          params: {
            restore_access_form: { restored_reason: "They didn't do anything wrong." },
          },
        )
      }
        .to change { user.reload.revoked_reason }.to(nil)
        .and change { user.revoked_at }.to(nil)
        .and change { user.bannable_action_count }.to(0)

      expect(response).to redirect_to(admin_early_access_user_path(user))
      expect(flash[:notice]).to eq("Access restored")
    end

    it "re-renders the edit page when given invalid params" do
      user = create(:early_access_user, :shadow_banned)
      patch(restore_admin_early_access_user_path(user), params: { restore_access_form: { restored_reason: "" } })

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to have_selector(".govuk-error-summary")
    end

    it "redirects to the user's page if the user's is not shadow banned or had their access revoked" do
      user = create(:early_access_user)
      patch restore_admin_early_access_user_path(user)
      expect(response).to redirect_to(admin_early_access_user_path(user))
    end
  end
end
