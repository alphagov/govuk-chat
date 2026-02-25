module Guardrails
  module Claude
    class MultipleChecker
      MAX_TOKENS = 100

      def self.call(...) = new(...).call

      def initialize(input, prompt)
        @input = input
        @prompt = prompt
        @anthropic_bedrock_client ||= Anthropic::BedrockClient.new(
          aws_region: ENV["CLAUDE_AWS_REGION"],
        )
      end

      def call
        claude_response = anthropic_bedrock_client.messages.create(
          system: [{ type: "text", text: prompt.system_prompt, cache_control: { type: "ephemeral" } }],
          model: BedrockModels.model_id(:claude_haiku),
          messages: [{ role: "user", content: prompt.user_prompt(input) }],
          max_tokens: MAX_TOKENS,
        )

        llm_response = claude_response.to_h
        llm_guardrail_result = llm_response[:content][0][:text]
        llm_token_usage = claude_response[:usage]

        {
          llm_response:,
          llm_guardrail_result:,
          llm_prompt_tokens: BedrockModels.claude_total_prompt_tokens(claude_response[:usage]),
          llm_completion_tokens: llm_token_usage[:output_tokens],
          llm_cached_tokens: llm_token_usage[:cache_read_input_tokens],
          model: claude_response[:model],
        }
      end

    private

      attr_reader :input, :anthropic_bedrock_client, :prompt
    end
  end
end
