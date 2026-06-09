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

  describe ".determine_model" do
    let(:bedrock_models) { described_class::MODEL_IDS.keys }
    let(:claude_models) { bedrock_models.select { |model_name| model_name.to_s.starts_with?("claude") } }
    let(:default_model) { claude_models.first }
    let(:supported_models) { claude_models }

    it "returns the default model and model name when requested model is not provided" do
      expect(described_class.determine_model(nil, default_model, supported_models))
        .to eq([described_class.model_id(default_model), default_model])
    end

    it "returns the requested model and corresponding model name when requested model is provided" do
      expect(described_class.determine_model(claude_models.second, default_model, supported_models))
        .to eq([described_class.model_id(claude_models.second), claude_models.second])
    end

    it "raises an error if the requested model is set to an unknown model" do
      expect { described_class.determine_model("unknown_model", default_model, supported_models) }
        .to raise_error("Unknown Bedrock model name: unknown_model")
    end

    it "raises an error if the requested model is set to an unsupported model" do
      non_claude_model = (bedrock_models - claude_models).first
      expect { described_class.determine_model(non_claude_model, default_model, supported_models) }
        .to raise_error("Unsupported model: #{non_claude_model}")
    end
  end

  describe ".expected_foundation_models" do
    it "returns the expected foundation models without the 'eu.' prefix" do
      allow(described_class).to receive(:MODEL_IDS).and_return({
        claude_sonnet_4_5: "eu.anthropic.claude-sonnet-4-5-20250929-v1:0",
        claude_haiku_4_5: "eu.anthropic.claude-haiku-4-5-20251001-v1:0",
        titan_embed_v2: "amazon.titan-embed-text-v2:0",
        openai_gpt_oss_120b: "openai.gpt-oss-120b-1:0",
      })

      expect(described_class.expected_foundation_models).to contain_exactly(
        "amazon.titan-embed-text-v2:0",
        "anthropic.claude-sonnet-4-5-20250929-v1:0",
        "anthropic.claude-haiku-4-5-20251001-v1:0",
        "openai.gpt-oss-120b-1:0",
      )
    end
  end
end
