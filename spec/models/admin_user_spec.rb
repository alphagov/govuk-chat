RSpec.describe AdminUser do
  describe "#flipper_id" do
    it "returns email if it is set" do
      user = build(:admin_user, email: "user@dev.gov.uk")
      expect(user.flipper_id).to eq("user@dev.gov.uk")
    end

    it "returns id if email is not set" do
      user = create(:admin_user, email: nil)
      expect(user.flipper_id).to eq(user.id)
    end
  end
end
