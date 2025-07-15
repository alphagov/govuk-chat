module Guardrails
  class JailbreakChecker
    Result = Data.define(
      :triggered,
      :llm_response,
      :llm_prompt_tokens,
      :llm_completion_tokens,
      :llm_cached_tokens,
      :model,
    )

    class ResponseError < StandardError
      attr_reader :llm_guardrail_result, :llm_response, :llm_prompt_tokens, :llm_completion_tokens, :llm_cached_tokens, :model

      def initialize(message,
                     llm_guardrail_result:,
                     llm_response:,
                     llm_prompt_tokens:,
                     llm_completion_tokens:,
                     llm_cached_tokens:,
                     model:)
        super(message)
        @llm_guardrail_result = llm_guardrail_result
        @llm_response = llm_response
        @llm_prompt_tokens = llm_prompt_tokens
        @llm_completion_tokens = llm_completion_tokens
        @llm_cached_tokens = llm_cached_tokens
        @model = model
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

      if result[:llm_guardrail_result] == pass_value
        create_result(result, triggered: false)
      else
        create_result(result, triggered: true)
      end
    end

  private

    attr_reader :input, :llm_provider

    delegate :guardrails_llm_prompts, :pass_value, to: :class

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
        model: result[:model],
      }
    end
  end
end
