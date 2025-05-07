RSpec.describe Search::TextToEmbedding do
  describe ".call" do
    let(:text) { "The text" }
    let(:provider) { :openai }

    it "calls the OpenAI embedding provider" do
      expect(Search::TextToEmbedding::OpenAI).to receive(:call).with(text)
      described_class.call(text, llm_provider: provider)
    end

    it "defaults to using OpenAI if no provider is specified" do
      expect(Search::TextToEmbedding::OpenAI).to receive(:call).with(text)
      described_class.call(text)
    end

    context "when an unknown provider is specified" do
      let(:provider) { :unknown_provider }

      it "raises an error" do
        expect { described_class.call(text, llm_provider: provider) }
          .to raise_error(RuntimeError, "Unknown provider: #{provider}")
      end
    end
  end
end
