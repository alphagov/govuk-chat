module Guardrails
  class JailbreakChecker
    PASS_VALUE = "0"
    FAIL_VALUE = "1"
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

    def self.call(...) = new(...).call

    def initialize(input, llm_provider)
      @input = input
      @llm_provider = llm_provider
    end

    def call
      case llm_provider
      when :openai
        result = OpenAI::JailbreakChecker.call(input)
      when :claude
        result = Claude::JailbreakChecker.call(input)
      end

      case result[:llm_guardrail_result]
      when FAIL_VALUE
        Result.new(triggered: true, llm_response: result[:llm_response], llm_token_usage: result[:llm_token_usage])
      when PASS_VALUE
        Result.new(triggered: false, llm_response: result[:llm_response], llm_token_usage: result[:llm_token_usage])
      else
        raise ResponseError.new(
          "Error parsing jailbreak guardrails response", result[:llm_guardrail_result], result[:llm_response], result[:llm_token_usage]
        )
      end
    end

  private

    attr_reader :input, :llm_provider
  end
end
