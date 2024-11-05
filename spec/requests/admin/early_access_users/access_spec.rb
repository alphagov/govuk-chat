RSpec.describe "Admin::EarlyAccessUsers::AccessController" do
  it_behaves_like "redirects to the admin_early_access_user_path if the user is revoked",
                  routes: {
                    revoke_admin_early_access_user_path: %i[get patch],
                    shadow_ban_admin_early_access_user_path: %i[get patch],
                  }

  it_behaves_like "redirects to the admin_early_access_user_path if the user is shadow banned",
                  routes: { shadow_ban_admin_early_access_user_path: %i[get patch] }

  it_behaves_like "redirects to the admin_early_access_user_path if the user has full access",
                  routes: { restore_admin_early_access_user_path: %i[get patch] }

  describe "GET :revoke" do
    it "renders the revoke access form" do
      user = create(:early_access_user)
      get revoke_admin_early_access_user_path(user)

      expect(response.body)
        .to have_content("Reason for revoking access")
        .and have_selector("textarea#revoke-reason")
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
  end

  describe "GET :shadow_ban" do
    it "renders the shadow ban access form" do
      user = create(:early_access_user)
      get shadow_ban_admin_early_access_user_path(user)

      expect(response.body)
        .to have_content("Reason for shadow ban")
        .and have_selector("textarea#shadow-ban-reason")
    end
  end

  describe "PATCH :shadow_ban_confirm" do
    let(:user) { create(:early_access_user) }

    it "updates the user's shadow banned attributes and redirects to the user's page" do
      expect {
        patch(
          shadow_ban_admin_early_access_user_path(user),
          params: {
            shadow_ban_form: { shadow_ban_reason: "Asking too many questions" },
          },
        )
      }
      .to change { user.reload.shadow_banned_reason }.to("Asking too many questions")

      expect(response).to redirect_to(admin_early_access_user_path(user))
      expect(flash[:notice]).to eq("User shadown banned")
    end

    it "re-renders the edit page when given invalid params" do
      patch(
        shadow_ban_admin_early_access_user_path(user),
        params: { shadow_ban_form: { shadow_ban_reason: "" } },
      )

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to have_selector(".govuk-error-summary")
    end
  end

  describe "GET :restore" do
    it "renders the page successfully" do
      user = create(:early_access_user, :shadow_banned)
      get restore_admin_early_access_user_path(user)

      expect(response).to have_http_status(:ok)
      expect(response.body).to have_content("Reason for restoring access")
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
  end
end
