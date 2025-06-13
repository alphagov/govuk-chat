RSpec.describe SignonUser do
  describe "has_permission?" do
    let(:user) { create(:signon_user, permissions: %w[permission]) }

    it "returns true if the user permissions include the specified permission" do
      expect(user.has_permission?("permission")).to be true
    end

    it "returns false if the user permissions don't include the specified permission" do
      expect(user.has_permission?("another-permission")).to be false
    end
  end
end
