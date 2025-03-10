module Guardrails
  module OpenAI
    class MultipleChecker
      OPENAI_MODEL = "gpt-4o-mini".freeze
      MAX_TOKENS_BUFFER = 5

      def self.call(...) = new(...).call

      def initialize(input, prompt)
        @input = input
        @prompt = prompt
        @openai_client = OpenAIClient.build
      end

      def call
        llm_response = openai_response.dig("choices", 0)
        llm_guardrail_result = llm_response.dig("message", "content")
        llm_token_usage = openai_response["usage"]

        unless response_pattern =~ llm_guardrail_result
          raise ::Guardrails::MultipleChecker::ResponseError.new(
            "Error parsing guardrail response", llm_guardrail_result, llm_token_usage
          )
        end

        parts = llm_guardrail_result.split(" | ")
        triggered = parts.first.chomp == "True"
        guardrails = if triggered
                       extract_guardrails(parts.second)
                     else
                       []
                     end
        ::Guardrails::MultipleChecker::Result.new(
          llm_response:,
          llm_guardrail_result:,
          triggered:,
          guardrails:,
          llm_token_usage:,
        )
      end

    private

      attr_reader :input, :openai_client, :prompt

      def openai_response
        @openai_response ||= openai_client.chat(
          parameters: {
            model: OPENAI_MODEL,
            messages:,
            temperature: 0.0,
            max_tokens:,
          },
        )
      end

      def messages
        [
          { role: "system", content: prompt.system_prompt },
          { role: "user", content: prompt.user_prompt(input) },
        ]
      end

      def max_tokens
        all_guardrail_numbers = guardrail_numbers.map(&:to_s).join(", ")
        longest_possible_response_string = %(True | "#{all_guardrail_numbers}")

        token_count = Tiktoken
         .encoding_for_model(OPENAI_MODEL)
         .encode(longest_possible_response_string)
         .length

        token_count + MAX_TOKENS_BUFFER
      end

      def guardrail_numbers
        prompt.guardrails.map(&:key)
      end

      def response_pattern
        @response_pattern ||= begin
          guardrail_range = "[#{guardrail_numbers.min}-#{guardrail_numbers.max}]"
          /^(False \| None|True \| "#{guardrail_range}(, #{guardrail_range})*")$/
        end
      end

      def extract_guardrails(parts)
        guardrail_numbers = parts.scan(/\d+/).map(&:to_i)
        prompt.guardrails.select { |guardrail| guardrail.key.in?(guardrail_numbers) }.map(&:name)
      end
    end
  end
end
