RSpec.describe Feature do
  let(:user) { build(:user) }

  context "when the feature is enabled for everyone" do
    before { Flipper.enable(:chat_api) }

    it "returns true for a user" do
      expect(described_class.enabled?(:chat_api, user)).to be(true)
    end

    it "returns true for no user" do
      expect(described_class.enabled?(:chat_api, nil)).to be(true)
    end
  end

  context "when the feature is disabled for everyone" do
    before { Flipper.disable(:chat_api) }

    it "returns false for a user" do
      expect(described_class.enabled?(:chat_api, user)).to be(false)
    end

    it "returns false for no user" do
      expect(described_class.enabled?(:chat_api, nil)).to be(false)
    end
  end

  context "when the feature is enabled for a user" do
    before { Flipper.enable(:chat_api, user) }

    it "returns true for the user" do
      expect(described_class.enabled?(:chat_api, user)).to be(true)
    end

    it "returns true when the user is Current.user" do
      allow(Current).to receive(:user).and_return(user)
      expect(described_class.enabled?(:chat_api)).to be(true)
    end

    it "returns false when a different user is Current.user" do
      allow(Current).to receive(:user).and_return(build(:user))
      expect(described_class.enabled?(:chat_api)).to be(false)
    end

    it "returns true when a different user is Current.user but the actual user is passed in" do
      allow(Current).to receive(:user).and_return(build(:user))
      expect(described_class.enabled?(:chat_api, user)).to be(true)
    end

    it "returns false when a nil user argument is passed in to replace Current.user" do
      allow(Current).to receive(:user).and_return(user)
      expect(described_class.enabled?(:chat_api, nil)).to be(false)
    end
  end
end
