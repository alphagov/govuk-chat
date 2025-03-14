module Guardrails
  module Claude
    class MultipleChecker
      BEDROCK_MODEL = "eu.anthropic.claude-3-5-sonnet-20240620-v1:0".freeze
      MAX_TOKENS = 100

      def self.call(...) = new(...).call

      def initialize(input, prompt)
        @input = input
        @prompt = prompt
        @bedrock_client = Aws::BedrockRuntime::Client.new
      end

      def call
        claude_response = bedrock_client.converse(
          system: [{ text: prompt.system_prompt }],
          model_id: BEDROCK_MODEL,
          messages: [{ role: "user", content: [{ text: prompt.user_prompt(input) }] }],
          inference_config: {
            max_tokens: MAX_TOKENS,
          },
        )

        llm_response = claude_response.output
        llm_guardrail_result = llm_response.dig("message", "content", 0, "text")
        llm_token_usage = claude_response.usage

        {
          llm_response:,
          llm_guardrail_result:,
          llm_prompt_tokens: llm_token_usage["input_tokens"],
          llm_completion_tokens: llm_token_usage["output_tokens"],
          llm_cached_tokens: nil,
        }
      end

    private

      attr_reader :input, :bedrock_client, :prompt
    end
  end
end
