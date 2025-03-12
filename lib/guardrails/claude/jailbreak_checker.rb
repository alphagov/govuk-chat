module Guardrails::Claude
  class JailbreakChecker
    BEDROCK_MODEL = "eu.anthropic.claude-3-5-sonnet-20240620-v1:0".freeze

    def self.call(...) = new(...).call

    def initialize(input)
      @input = input
    end

    def call
      response = bedrock_client.converse(
        system: [{ text: system_prompt }],
        model_id: BEDROCK_MODEL,
        messages:,
        inference_config:,
      )

      {
        llm_response: response.output,
        llm_guardrail_result: response.dig("output", "message", "content", 0, "text"),
        llm_prompt_tokens: response.usage["input_tokens"],
        llm_completion_tokens: response.usage["output_tokens"],
        llm_cached_tokens: nil,
      }
    end

  private

    attr_reader :input

    def max_tokens
      guardrails_llm_prompts.fetch(:max_tokens)
    end

    def guardrails_llm_prompts
      Rails.configuration.govuk_chat_private.llm_prompts.claude.jailbreak_guardrails
    end

    def bedrock_client
      @bedrock_client ||= Aws::BedrockRuntime::Client.new
    end

    def inference_config
      {
        max_tokens: 10,
        temperature: 0.0,
      }
    end

    def messages
      [{ role: "user", content: [{ text: user_prompt }] }]
    end

    def user_prompt
      guardrails_llm_prompts[:user_prompt].sub("{input}", input)
    end

    def system_prompt
      guardrails_llm_prompts[:system_prompt]
    end
  end
end
