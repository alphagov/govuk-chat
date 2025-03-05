module Guardrails
  module Claude
    class MultipleChecker
      BEDROCK_MODEL = "eu.anthropic.claude-3-5-sonnet-20240620-v1:0".freeze
      MAX_TOKENS_BUFFER = 5

      def self.call(...) = new(...).call

      def initialize(input, llm_prompt_name)
        @input = input
        @llm_prompt_name = llm_prompt_name
        @bedrock_client = Aws::BedrockRuntime::Client.new
        @prompt_loader = ::Guardrails::MultipleChecker::Prompt
      end

      def call
        claude_response = bedrock_client.converse(
          system: [{ text: prompt.system_prompt }],
          model_id: BEDROCK_MODEL,
          messages: [{ role: "user", content: [{ text: prompt.user_prompt(input) }] }],
        )

        llm_response = claude_response.output
        llm_guardrail_result = llm_response.dig("message", "content", 0, "text")
        llm_token_usage = claude_response.usage

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

      attr_reader :input, :llm_prompt_name, :bedrock_client, :prompt_loader

      def prompt
        @prompt ||= prompt_loader.new(llm_prompt_name, :claude)
      end

      def extract_guardrails(parts)
        guardrail_numbers = parts.scan(/\d+/).map(&:to_i)
        prompt.guardrails.select { |guardrail| guardrail.key.in?(guardrail_numbers) }.map(&:name)
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
    end
  end
end
