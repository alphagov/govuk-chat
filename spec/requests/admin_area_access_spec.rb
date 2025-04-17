RSpec.describe "Admin area access" do
  describe "GET /admin" do
    context "when a signed in user has 'admin-area' permission" do
      it "returns a successful response" do
        user = create(:signon_user, :admin)
        login_as(user)

        get "/admin"

        expect(response).to have_http_status(:success)
      end
    end

    context "when the user does not have the 'admin-area' permission" do
      it "returns a forbidden response" do
        user = create(:signon_user)
        login_as(user)

        get "/admin"

        expect(response).to have_http_status(:forbidden)
      end
    end
  end
end
