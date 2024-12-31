module Guardrails
  class JailbreakChecker
    Result = Data.define(:triggered, :llm_response, :llm_token_usage)
    class ResponseError < StandardError
      attr_reader :llm_guardrail_result, :llm_response, :llm_token_usage

      def initialize(message, llm_guardrail_result:, llm_response:, llm_token_usage:)
        super(message)
        @llm_guardrail_result = llm_guardrail_result
        @llm_response = llm_response
        @llm_token_usage = llm_token_usage
      end
    end

    OPENAI_MODEL = "gpt-4o-mini".freeze

    def self.max_tokens
      guardrails_llm_prompts.fetch(:max_tokens)
    end

    def self.logit_bias
      guardrails_llm_prompts.fetch(:logit_bias)
    end

    def self.pass_value
      guardrails_llm_prompts.fetch(:pass_value)
    end

    def self.fail_value
      guardrails_llm_prompts.fetch(:fail_value)
    end

    def self.guardrails_llm_prompts
      Rails.configuration.govuk_chat_private.llm_prompts.jailbreak_guardrails
    end

    def self.call(...) = new(...).call

    def initialize(input)
      @input = input
      @openai_client = OpenAIClient.build
    end

    def call
      llm_response = openai_response.dig("choices", 0)
      llm_guardrail_result = llm_response.dig("message", "content")
      llm_token_usage = openai_response["usage"]

      case llm_guardrail_result
      when fail_value
        Result.new(triggered: true, llm_response:, llm_token_usage:)
      when pass_value
        Result.new(triggered: false, llm_response:, llm_token_usage:)
      else
        raise ResponseError.new(
          "Error parsing jailbreak guardrails response", llm_guardrail_result:, llm_response:, llm_token_usage:
        )
      end
    end

  private

    attr_reader :input, :openai_client

    delegate :guardrails_llm_prompts, :max_tokens, :logit_bias, :pass_value, :fail_value, to: :class

    def openai_response
      @openai_response ||= openai_client.chat(
        parameters: {
          model: OPENAI_MODEL,
          messages:,
          temperature: 0.0,
          max_tokens:,
          logit_bias:,
        },
      )
    end

    def messages
      user_prompt = guardrails_llm_prompts[:user_prompt].sub("{input}", input)
      [
        { role: "system", content: guardrails_llm_prompts[:system_prompt] },
        { role: "user", content: user_prompt },
      ]
    end
  end
end
