RSpec.describe Feature do
  let(:anon_user) { AnonymousUser.new("some-id") }

  setup do
    stub_feature_flag(:chat_api, true)
  end

  context "without a user" do
    before do
      allow(Current).to receive(:user).and_return(nil)
    end

    it "calls flipper with only the feature" do
      expect(described_class.enabled?(:chat_api)).to eq(true)
      expect(Flipper).to have_received(:enabled?).with(:chat_api)
    end
  end

  context "with a current user" do
    before do
      allow(Current).to receive(:user).and_return(anon_user)
    end

    it "calls flipper with the feature and user" do
      expect(described_class.enabled?(:chat_api)).to eq(true)
      expect(Flipper).to have_received(:enabled?).with(:chat_api, anon_user)
    end

    it "allows overriding the user" do
      another_user = AnonymousUser.new("another-id")
      expect(described_class.enabled?(:chat_api, another_user)).to eq(true)
      expect(Flipper).to have_received(:enabled?).with(:chat_api, another_user)
    end
  end
end
