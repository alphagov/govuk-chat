RSpec.describe BedrockModels do
  describe ".total_prompt_tokens" do
    it "returns the total prompt tokens from usage" do
      usage = {
        input_tokens: 10,
        cache_read_input_tokens: 5,
        cache_write_input_tokens: 2,
      }
      expect(described_class.total_prompt_tokens(usage)).to eq(17)
    end

    it "returns 0 when no tokens are provided" do
      usage = {}
      expect(described_class.total_prompt_tokens(usage)).to eq(0)
    end

    it "handles nil values gracefully" do
      usage = {
        input_tokens: nil,
        cache_read_input_tokens: nil,
        cache_write_input_tokens: nil,
      }
      expect(described_class.total_prompt_tokens(usage)).to eq(0)
    end
  end
end
