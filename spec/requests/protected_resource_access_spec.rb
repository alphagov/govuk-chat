RSpec.describe "accessing resources with passwordless" do
  context "when not logged in" do
    it "redirects to /chat/sign_in" do
      get protected_path
      expect(response).to redirect_to(early_access_entry_path)
    end
  end

  context "when logged in as an EarlyAccessuser" do
    let(:user) { create :early_access_user }

    before do
      passwordless_sign_in(user)
    end

    it "allows access" do
      get protected_path
      expect(response).to have_http_status(:ok)
                          .and have_attributes(body: /You got here/)
    end
  end
end
