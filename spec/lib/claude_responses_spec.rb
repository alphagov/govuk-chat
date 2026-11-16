RSpec.describe ClaudeResponses do
  let(:claude_responses) { Class.new { include ClaudeResponses }.new }
  let(:text_block) { claude_messages_text_block("An answer") }
  let(:tool_use_block) { claude_messages_tool_use_block(input: { answer: "An answer" }, name: "output_schema") }

  def response_with(*content, stop_reason: :end_turn)
    claude_messages_response(content:, stop_reason:, bedrock_model: :claude_sonnet_4_5)
  end

  describe "#claude_first_text_content" do
    it "returns the first text block, after any other blocks" do
      response = response_with(claude_messages_thinking_block, text_block)

      expect(claude_responses.claude_first_text_content(response).text).to eq("An answer")
    end

    it "raises a MissingContentError naming the stop reason when there's no text block" do
      response = response_with(tool_use_block, stop_reason: :tool_use)

      expect { claude_responses.claude_first_text_content(response) }
        .to raise_error(ClaudeResponses::MissingContentError, "Claude response has no text block (stop_reason: tool_use)")
    end
  end

  describe "#claude_first_tool_use" do
    it "returns the first tool use block, after any other blocks" do
      response = response_with(claude_messages_thinking_block, tool_use_block, stop_reason: :tool_use)

      expect(claude_responses.claude_first_tool_use(response).name).to eq("output_schema")
    end

    it "raises a MissingContentError naming the stop reason when there's no tool use block" do
      response = response_with(text_block)

      expect { claude_responses.claude_first_tool_use(response) }
        .to raise_error(ClaudeResponses::MissingContentError, "Claude response has no tool_use block (stop_reason: end_turn)")
    end
  end

  describe "#claude_total_prompt_tokens" do
    it "returns the total prompt tokens from usage" do
      usage = Anthropic::Models::Usage.new(
        input_tokens: 10,
        output_tokens: 20,
        cache_read_input_tokens: 5,
        cache_creation_input_tokens: 2,
      )
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
        cache_creation_input_tokens: nil,
      }
      expect(claude_responses.claude_total_prompt_tokens(usage)).to eq(0)
    end
  end
end
