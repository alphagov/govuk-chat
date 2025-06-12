RSpec.describe Guardrails::Claude::JailbreakChecker do
  let(:input) { "User question" }

  describe ".call" do
    it "calls Claude to check for jailbreak attempts" do
      prompts = Rails.configuration.govuk_chat_private.llm_prompts.claude.jailbreak_guardrails
      allow(prompts).to receive(:[]).and_call_original
      allow(prompts).to receive(:[]).with(:system_prompt).and_return("The system prompt")
      allow(prompts).to receive(:[]).with(:user_prompt).and_return("{input}")

      guardrail_result = Guardrails::JailbreakChecker.pass_value

      client = stub_bedrock_converse(
        bedrock_claude_text_response(guardrail_result, user_message: Regexp.new(input)),
      )

      described_class.call(input)
      expect(client.api_requests.size).to eq(1)
    end

    it "uses an overridden AWS region if set" do
      ClimateControl.modify(CLAUDE_AWS_REGION: "my-region") do
        bedrock_client = Aws::BedrockRuntime::Client.new(stub_responses: true)

        allow(Aws::BedrockRuntime::Client).to(
          receive(:new).with(region: "my-region").and_return(bedrock_client),
        )

        guardrail_result = Guardrails::JailbreakChecker.pass_value
        bedrock_client.stub_responses(
          :converse,
          bedrock_claude_text_response(guardrail_result, user_message: Regexp.new(input)),
        )

        described_class.call(input)
        expect(bedrock_client.api_requests.size).to eq(1)
      end
    end
  end
end
