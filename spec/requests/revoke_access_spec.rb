RSpec.describe "RevokeAccessController" do
  describe "GET :revoke" do
    it "return a 404 homepage if the token is invalid" do
      get early_access_user_unsubscribe_path("invalid-token")

      expect(response).to have_http_status(:not_found)
    end

    it "renders the unsubscribe page if the token is valid" do
      user = create(:early_access_user)

      get early_access_user_unsubscribe_path(user.revoke_access_token)

      expect(response).to have_http_status(:success)
      expect(response.body).to have_selector("form[action='#{early_access_user_unsubscribe_confirm_path(user.revoke_access_token)}']")
      expect(response.body).to have_selector("form .govuk-button", text: "Unsubscribe")
    end
  end

  describe "POST :revoke_confirm" do
    let(:user) { create(:early_access_user) }
    let(:token) { user.revoke_access_token }

    before do
      create :conversation, user:
    end

    it "deletes the early access user" do
      expect { post early_access_user_unsubscribe_confirm_path(token:) }.to change(EarlyAccessUser, :count).by(-1)
    end

    it "leaves the conversations in place" do
      expect { post early_access_user_unsubscribe_confirm_path(token:) }.not_to change(Conversation, :count)
    end

    it "redirects to the homepage" do
      post early_access_user_unsubscribe_confirm_path(token:)
      expect(response).to redirect_to(homepage_path)
    end

    it "does not revoke access for any user" do
      expect { post early_access_user_unsubscribe_confirm_path("invalid-token") }
        .not_to change(EarlyAccessUser.where.not(revoked_at: nil), :count)
      expect(response).to redirect_to(homepage_path)
    end
  end
end
