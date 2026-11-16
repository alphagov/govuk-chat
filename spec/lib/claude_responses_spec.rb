RSpec.describe ClaudeResponses do
  let(:claude_responses) { Class.new { include ClaudeResponses }.new }

  describe "#claude_total_prompt_tokens" do
    it "returns the total prompt tokens from usage" do
      usage = {
        input_tokens: 10,
        cache_read_input_tokens: 5,
        cache_write_input_tokens: 2,
      }
      expect(claude_responses.claude_total_prompt_tokens(usage)).to eq(17)
    end

    it "returns 0 when no tokens are provided" do
      usage = {}
      expect(claude_responses.claude_total_prompt_tokens(usage)).to eq(0)
    end

    it "handles nil values gracefully" do
      usage = {
        input_tokens: nil,
        cache_read_input_tokens: nil,
        cache_write_input_tokens: nil,
      }
      expect(claude_responses.claude_total_prompt_tokens(usage)).to eq(0)
    end
  end
end
