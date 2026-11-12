RSpec.describe AnswerComposition::Pipeline::ClaudeResponse do
  describe ".content_block" do
    let(:text_block) { claude_messages_text_block("An answer") }

    def response(content:, stop_reason: :end_turn)
      claude_messages_response(content:, stop_reason:, bedrock_model: :claude_sonnet_4_5)
    end

    it "returns the first block of the requested type" do
      content = [claude_messages_thinking_block, text_block]

      expect(described_class.content_block(response(content:), :text)).to eq(text_block)
    end

    it "raises an error when there is no block of the requested type" do
      expect { described_class.content_block(response(content: [text_block], stop_reason: :end_turn), :tool_use) }
        .to raise_error(described_class::UnexpectedResponseError, "Claude response has no tool_use block (stop_reason: end_turn)")
    end

    it "raises an error when Claude refuses to respond" do
      expect { described_class.content_block(response(content: [text_block], stop_reason: :refusal), :text) }
        .to raise_error(described_class::UnexpectedResponseError, "Claude refused to respond")
    end
  end
end
