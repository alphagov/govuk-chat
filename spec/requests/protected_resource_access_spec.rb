RSpec.describe "accessing resources with passwordless" do
  context "when not logged in" do
    it "redirects to /chat/sign_in" do
      get protected_path
      expect(response).to redirect_to(early_access_entry_path)
    end
  end

  context "when logged in as an EarlyAccessuser" do
    let(:user) { create :early_access_user }

    before { sign_in_early_access_user(user) }

    it "allows access" do
      get protected_path
      expect(response).to have_http_status(:ok)
                          .and have_attributes(body: /You got here/)
    end
  end

  context "when logged in but user has had their access revoked" do
    let(:user) { create :early_access_user }

    before do
      sign_in_early_access_user(user)
      user.touch(:revoked_at)
    end

    it "prevents access and redirects to a sign in page" do
      get protected_path
      expect(response).to redirect_to(early_access_entry_path)
    end
  end
end
