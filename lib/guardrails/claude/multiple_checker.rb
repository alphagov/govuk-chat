module Guardrails
  module Claude
    class MultipleChecker
      MAX_TOKENS = 100

      def self.call(...) = new(...).call

      def initialize(input, prompt)
        @input = input
        @prompt = prompt
        @anthropic_client ||= Anthropic::VertexClient.new(
          region: "europe-west1",
          project_id: "gov-uk-chat-integration",
        )
      end

      def call
        claude_response = anthropic_client.messages.create(
          system: [{ type: "text", text: prompt.system_prompt, cache_control: { type: "ephemeral" } }],
          model: "claude-sonnet-4@20250514",
          messages: [{ role: "user", content: prompt.user_prompt(input) }],
          max_tokens: MAX_TOKENS,
        )

        llm_response = claude_response.to_h
        llm_guardrail_result = llm_response[:content][0][:text]
        llm_token_usage = claude_response[:usage]

        {
          llm_response:,
          llm_guardrail_result:,
          llm_prompt_tokens: llm_token_usage[:input_tokens],
          llm_completion_tokens: llm_token_usage[:output_tokens],
          llm_cached_tokens: llm_token_usage[:cache_read_input_tokens],
        }
      end

    private

      attr_reader :input, :anthropic_client, :prompt
    end
  end
end
