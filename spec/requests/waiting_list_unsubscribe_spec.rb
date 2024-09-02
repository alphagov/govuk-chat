RSpec.describe "WaitingListUnsubscribeController" do
  shared_examples "renders a 404 for invalid params" do |method, path|
    it "returns a 404 if user ID is invalid" do
      process(method.to_sym, public_send(path.to_sym, -1, "token"))
      expect(response).to have_http_status(:not_found)
    end

    it "returns a 404 if the token is invalid" do
      user = create(:waiting_list_user)
      process(method.to_sym, public_send(path.to_sym, user.id, "invalid-token"))
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "GET :unsubscribe" do
    it_behaves_like "renders a 404 for invalid params", :get, :waiting_list_user_unsubscribe_path

    it "renders the unsubscribe page if the token is valid" do
      user = create(:waiting_list_user)
      get waiting_list_user_unsubscribe_path(user.id, user.unsubscribe_token)

      expect(response).to have_http_status(:success)
      expect(response.body).to have_content "Unsubscribe"
    end
  end

  describe "POST :unsubscribe_confirm" do
    it_behaves_like "renders a 404 for invalid params", :post, :waiting_list_user_unsubscribe_confirm_path

    it "deletes the user if the token is valid" do
      user = create(:waiting_list_user)
      post waiting_list_user_unsubscribe_confirm_path(user.id, user.unsubscribe_token)

      expect(WaitingListUser.exists?(user.id)).to be(false)
    end
  end
end
