RSpec.describe Feature do
  let(:user) { build(:admin_user) }
  let(:feature) { :my_feature }

  context "when the feature is enabled for everyone" do
    before { Flipper.enable(feature) }

    it "returns true for a user" do
      expect(described_class.enabled?(feature, user)).to be(true)
    end

    it "returns true for no user" do
      expect(described_class.enabled?(feature, nil)).to be(true)
    end
  end

  context "when the feature is disabled for everyone" do
    before { Flipper.disable(feature) }

    it "returns false for a user" do
      expect(described_class.enabled?(feature, user)).to be(false)
    end

    it "returns false for no user" do
      expect(described_class.enabled?(feature, nil)).to be(false)
    end
  end

  context "when the feature is enabled for a user" do
    before { Flipper.enable(feature, user) }

    it "returns true for the user" do
      expect(described_class.enabled?(feature, user)).to be(true)
    end

    it "returns true when the user is Current.admin_user" do
      allow(Current).to receive(:admin_user).and_return(user)
      expect(described_class.enabled?(feature)).to be(true)
    end

    it "returns false when a different user is Current.admin_user" do
      allow(Current).to receive(:admin_user).and_return(build(:admin_user))
      expect(described_class.enabled?(feature)).to be(false)
    end

    it "returns true when a different user is Current.admin_user but the actual user is passed in" do
      allow(Current).to receive(:admin_user).and_return(build(:admin_user))
      expect(described_class.enabled?(feature, user)).to be(true)
    end

    it "returns false when a nil user argument is passed in to replace Current.admin_user" do
      allow(Current).to receive(:admin_user).and_return(user)
      expect(described_class.enabled?(feature, nil)).to be(false)
    end
  end
end
