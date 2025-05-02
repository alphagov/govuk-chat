module Guardrails
  class JailbreakChecker
    Result = Data.define(:triggered, :llm_response, :llm_prompt_tokens, :llm_completion_tokens, :llm_cached_tokens)

    class ResponseError < StandardError
      attr_reader :llm_guardrail_result, :llm_response, :llm_prompt_tokens, :llm_completion_tokens, :llm_cached_tokens

      def initialize(message, llm_guardrail_result:, llm_response:, llm_prompt_tokens:, llm_completion_tokens:, llm_cached_tokens:)
        super(message)
        @llm_guardrail_result = llm_guardrail_result
        @llm_response = llm_response
        @llm_prompt_tokens = llm_prompt_tokens
        @llm_completion_tokens = llm_completion_tokens
        @llm_cached_tokens = llm_cached_tokens
      end

      def as_json
        {
          message:,
          llm_guardrail_result:,
          llm_response:,
          llm_prompt_tokens:,
          llm_completion_tokens:,
          llm_cached_tokens:,
        }
      end
    end

    def self.pass_value
      guardrails_llm_prompts.fetch(:pass_value)
    end

    def self.fail_value
      guardrails_llm_prompts.fetch(:fail_value)
    end

    def self.guardrails_llm_prompts
      Rails.configuration.govuk_chat_private.llm_prompts.common.jailbreak_guardrails
    end

    def self.call(...) = new(...).call

    def initialize(input, llm_provider = :openai)
      @input = input
      @llm_provider = llm_provider
    end

    def call
      case llm_provider
      when :openai
        result = OpenAI::JailbreakChecker.call(input)
      when :claude
        result = Claude::JailbreakChecker.call(input)
      else
        raise "Unexpected provider #{llm_provider}"
      end

      case result[:llm_guardrail_result]
      when fail_value
        create_result(result, triggered: true)
      when pass_value
        create_result(result, triggered: false)
      else
        raise ResponseError.new(
          "Error parsing jailbreak guardrails response",
          llm_guardrail_result: result[:llm_guardrail_result],
          **result_attributes(result),
        )
      end
    end

  private

    attr_reader :input, :llm_provider

    delegate :guardrails_llm_prompts, :pass_value, :fail_value, to: :class

    def create_result(result, triggered:)
      Result.new(
        triggered:,
        **result_attributes(result),
      )
    end

    def result_attributes(result)
      {
        llm_response: result[:llm_response],
        llm_prompt_tokens: result[:llm_prompt_tokens],
        llm_completion_tokens: result[:llm_completion_tokens],
        llm_cached_tokens: result[:llm_cached_tokens],
      }
    end
  end
end
