module Guardrails::Claude
  class JailbreakChecker
    def self.bedrock_model
      ENV["BEDROCK_CLAUDE_JAILBREAK_GUARDRAILS_MODEL"] || :claude_sonnet_4_0
    end

    def self.call(...) = new(...).call

    def initialize(input)
      @input = input
    end

    def call
      response = anthropic_bedrock_client.messages.create(
        system: [{ type: "text", text: system_prompt }],
        model: BedrockModels.model_id(self.class.bedrock_model.to_sym),
        messages:,
        **inference_config,
      )

      {
        llm_response: response.to_h,
        llm_guardrail_result: response[:content][0][:text],
        llm_prompt_tokens: response[:usage][:input_tokens],
        llm_completion_tokens: response[:usage][:output_tokens],
        llm_cached_tokens: nil,
        model: response[:model],
      }
    end

  private

    attr_reader :input

    def max_tokens
      guardrails_llm_prompts.fetch(:max_tokens)
    end

    def guardrails_llm_prompts
      Claude.prompt_config(jailbreak_checker, self.class.bedrock_model)
    end

    def anthropic_bedrock_client
      @anthropic_bedrock_client ||= Anthropic::BedrockClient.new(
        aws_region: ENV["CLAUDE_AWS_REGION"],
      )
    end

    def inference_config
      {
        max_tokens: max_tokens,
        temperature: 0.0,
      }
    end

    def messages
      [{ role: "user", content: user_prompt }]
    end

    def user_prompt
      guardrails_llm_prompts[:user_prompt].sub("{input}", input)
    end

    def system_prompt
      guardrails_llm_prompts[:system_prompt]
    end
  end
end
