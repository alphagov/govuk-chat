RSpec.describe "WaitingListUnsubscribeController" do
  describe "GET :unsubscribe" do
    it "returns a 404 if user ID is invalid" do
      get waiting_list_user_unsubscribe_path(-1, "token")

      expect(response).to have_http_status(:not_found)
    end

    it "returns a 404 if the token is invalid" do
      user = create(:waiting_list_user)

      get waiting_list_user_unsubscribe_path(user.id, "invalid-token")

      expect(response).to have_http_status(:not_found)
    end

    it "does not unsubscribe for a HEAD request" do
      user = create(:waiting_list_user)

      head waiting_list_user_unsubscribe_path(user.id, user.unsubscribe_token)

      expect(WaitingListUser.exists?(user.id)).to be(true)
      expect(response).to have_http_status(:ok)
      expect(response.body).to be_empty
    end

    context "when the token is valid" do
      let(:user) { create(:waiting_list_user) }

      it "deletes the user" do
        get waiting_list_user_unsubscribe_path(user.id, user.unsubscribe_token)

        expect(WaitingListUser.exists?(user.id)).to be(false)
      end

      it "renders the unsubscribe page" do
        get waiting_list_user_unsubscribe_path(user.id, user.unsubscribe_token)

        expect(response).to have_http_status(:ok)
        expect(response.body).to have_content "You’ve opted out of GOV.UK Chat"
      end
    end
  end
end
