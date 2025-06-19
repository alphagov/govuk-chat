RSpec.describe Guardrails::Claude::JailbreakChecker, :aws_credentials_stubbed do
  let(:input) { "User question" }

  describe ".call" do
    it "calls Claude to check for jailbreak attempts and returns the expected result" do
      stub_claude_jailbreak_guardrails(input, triggered: false)
      result = described_class.call(input)
      expect(result[:llm_guardrail_result]).to eq("PassValue")
    end

    it "returns the LLM token usage" do
      stub_claude_jailbreak_guardrails(input, triggered: false)

      result = described_class.call(input)

      expect(result[:llm_prompt_tokens]).to eq(10)
      expect(result[:llm_completion_tokens]).to eq(20)
      expect(result[:llm_cached_tokens]).to be_nil
    end

    it "returns the LLM response" do
      stub_claude_jailbreak_guardrails(input, triggered: false)

      result = described_class.call(input)

      expect(result[:llm_response]).to match(
        id: "msg-id",
        content: [
          have_attributes(
            text: "PassValue",
            type: :text,
          ),
        ],
        model: BedrockModels::CLAUDE_SONNET,
        role: :assistant,
        stop_reason: :end_turn,
        type: :message,
        usage: have_attributes(
          cache_read_input_tokens: nil,
          input_tokens: 10,
          output_tokens: 20,
        ),
      )
    end

    it "uses an overridden AWS region if set" do
      ClimateControl.modify(CLAUDE_AWS_REGION: "my-region") do
        allow(Anthropic::BedrockClient).to receive(:new).and_call_original
        anthropic_request = stub_claude_jailbreak_guardrails(input, triggered: false)

        described_class.call(input)

        expect(Anthropic::BedrockClient)
          .to have_received(:new).with(hash_including(aws_region: "my-region"))
        expect(anthropic_request).to have_been_made
      end
    end
  end
end
