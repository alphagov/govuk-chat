RSpec.describe Search::TextToEmbedding do
  describe ".call" do
    let(:text) { "The text" }

    it "calls the Titan embedding provider" do
      expect(Search::TextToEmbedding::Titan).to receive(:call).with("Text")
      described_class.call("Text")
    end
  end
end
