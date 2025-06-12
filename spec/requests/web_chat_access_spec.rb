RSpec.describe "Web chat access" do
  describe "GET /chat" do
    context "when a signed in user has 'web-chat' permission" do
      it "returns a successful response" do
        user = create(:signon_user, :web_chat)
        login_as(user)

        get homepage_path

        expect(response).to have_http_status(:success)
      end
    end

    context "when the user does not have the 'web-chat' permission" do
      it "returns a forbidden response" do
        user = create(:signon_user)
        login_as(user)

        get homepage_path

        expect(response).to have_http_status(:forbidden)
      end
    end
  end
end
