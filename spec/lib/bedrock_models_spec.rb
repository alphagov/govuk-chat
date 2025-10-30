RSpec.describe BedrockModels do
  describe ".claude_total_prompt_tokens" do
    it "returns the total prompt tokens from usage" do
      usage = {
        input_tokens: 10,
        cache_read_input_tokens: 5,
        cache_write_input_tokens: 2,
      }
      expect(described_class.claude_total_prompt_tokens(usage)).to eq(17)
    end

    it "returns 0 when no tokens are provided" do
      usage = {}
      expect(described_class.claude_total_prompt_tokens(usage)).to eq(0)
    end

    it "handles nil values gracefully" do
      usage = {
        input_tokens: nil,
        cache_read_input_tokens: nil,
        cache_write_input_tokens: nil,
      }
      expect(described_class.claude_total_prompt_tokens(usage)).to eq(0)
    end
  end

  describe ".model_id" do
    it "returns the correct model ID for a given model name" do
      expect(described_class.model_id(:titan_embed_v2)).to eq("amazon.titan-embed-text-v2:0")
    end

    it "raises an error for an unknown model name" do
      expect { described_class.model_id(:unknown_model) }.to raise_error(
        "Unknown Bedrock model name: unknown_model",
      )
    end
  end

  describe ".expected_foundation_models" do
    it "returns the expected foundation models without the 'eu.' prefix" do
      allow(described_class).to receive(:MODEL_IDS).and_return({
        claude_sonnet: "eu.anthropic.claude-haiku-4-5-20251001-v1:0",
        titan_embed_v2: "amazon.titan-embed-text-v2:0",
      })

      expect(described_class.expected_foundation_models).to contain_exactly(
        "amazon.titan-embed-text-v2:0",
        "anthropic.claude-haiku-4-5-20251001-v1:0",
      )
    end
  end
end
