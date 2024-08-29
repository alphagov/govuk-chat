RSpec.describe "RevokeAccessController" do
  describe "GET :revoke" do
    it "redirects to the homepage if the token is invalid" do
      get early_access_user_revoke_access_path("invalid-token")

      expect(response).to redirect_to(homepage_path)
    end

    it "renders the unsubscribe page if the token is valid" do
      user = create(:early_access_user)

      get early_access_user_revoke_access_path(token: user.revoke_access_token)

      expect(response).to have_http_status(:success)
      expect(response.body).to have_content "Revoke"
    end
  end

  describe "POST :revoke_confirm" do
    it "sets revoked_at on the user if the token is valid" do
      freeze_time do
        user = create(:early_access_user)
        token = user.revoke_access_token
        post early_access_user_revoke_access_confirm_path(token:)

        expect(EarlyAccessUser.find_by(revoke_access_token: token).revoked_at).to eq(Time.zone.now)
        expect(response).to redirect_to(homepage_path)
      end
    end

    it "does not revoke access for any user" do
      expect { post early_access_user_revoke_access_confirm_path("invalid-token") }
        .not_to change(EarlyAccessUser.where.not(revoked_at: nil), :count)
      expect(response).to redirect_to(homepage_path)
    end
  end
end
