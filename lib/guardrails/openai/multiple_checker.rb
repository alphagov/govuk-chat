module Guardrails
  module OpenAI
    class MultipleChecker
      OPENAI_MODEL = "gpt-4o-mini".freeze
      MAX_TOKENS = 100

      def self.call(...) = new(...).call

      def initialize(input, prompt)
        @input = input
        @prompt = prompt
        @openai_client = OpenAIClient.build
      end

      def call
        llm_token_usage = openai_response["usage"]

        {
          llm_response: openai_response.dig("choices", 0),
          llm_guardrail_result: openai_response.dig("choices", 0, "message", "content"),
          llm_prompt_tokens: llm_token_usage["prompt_tokens"],
          llm_completion_tokens: llm_token_usage["completion_tokens"],
          llm_cached_tokens: llm_token_usage.dig("prompt_tokens_details", "cached_tokens"),
          model: openai_response["model"],
        }
      end

    private

      attr_reader :input, :openai_client, :prompt

      def openai_response
        @openai_response ||= openai_client.chat(
          parameters: {
            model: OPENAI_MODEL,
            messages:,
            temperature: 0.0,
            max_tokens: MAX_TOKENS,
          },
        )
      end

      def messages
        [
          { role: "system", content: prompt.system_prompt },
          { role: "user", content: prompt.user_prompt(input) },
        ]
      end
    end
  end
end
