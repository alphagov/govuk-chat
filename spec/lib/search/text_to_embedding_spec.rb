RSpec.describe Search::TextToEmbedding do
  describe ".call" do
    let(:text) { "The text" }

    it "calls the Titan embedding provider" do
      expect(Search::TextToEmbedding::Titan).to receive(:call).with(text)
      described_class.call(text, llm_provider: :titan)
    end

    context "when an unknown provider is specified" do
      it "raises an error" do
        expect { described_class.call(text, llm_provider: "notreal") }
          .to raise_error(RuntimeError, "Unknown provider: notreal")
      end
    end
  end
end
