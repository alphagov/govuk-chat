module Guardrails::OpenAI
  class JailbreakChecker
    OPENAI_MODEL = "gpt-4o-mini".freeze

    def self.max_tokens
      guardrails_llm_prompts.fetch(:max_tokens)
    end

    def self.logit_bias
      guardrails_llm_prompts.fetch(:logit_bias)
    end

    def self.guardrails_llm_prompts
      Rails.configuration.govuk_chat_private.llm_prompts.openai.jailbreak_guardrails
    end

    def self.call(...) = new(...).call

    def initialize(input)
      @input = input
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

    attr_reader :input, :openai_client

    delegate :guardrails_llm_prompts, :max_tokens, :logit_bias, to: :class

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
