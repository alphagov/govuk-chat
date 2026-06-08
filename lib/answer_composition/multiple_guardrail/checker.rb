module AnswerComposition::MultipleGuardrail
  class Checker
    Result = Data.define(:triggered, :guardrails, :llm_response, :llm_guardrail_result,
                         :llm_prompt_tokens, :llm_completion_tokens, :llm_cached_tokens, :model) do
      def triggered_guardrails
        return [] unless guardrails

        guardrails.select { |_, v| v }.keys
      end
    end

    MAX_TOKENS = 100
    SUPPORTED_MODELS = %i[claude_haiku_4_5].freeze
    DEFAULT_MODEL = :claude_haiku_4_5

    attr_reader :input, :llm_provider, :llm_prompt_name

    def self.call(...) = new(...).call

    def self.bedrock_model
      BedrockModels.determine_model(ENV["BEDROCK_CLAUDE_GUARDRAILS_MODEL"], DEFAULT_MODEL, SUPPORTED_MODELS).last
    end

    def initialize(input, llm_prompt_name)
      @input = input
      @llm_prompt_name = llm_prompt_name
    end

    def call
      shared_config = {
        system: [{ type: "text", text: prompt.system_prompt, cache_control: { type: "ephemeral" } }],
        model: BedrockModels.model_id(self.class.bedrock_model),
        messages: [{ role: "user", content: prompt.user_prompt(input) }],
        max_tokens: MAX_TOKENS,
      }

      response = anthropic_bedrock_client.messages.create(**shared_config.merge(
        output_config: {
          format: json_schema,
        },
      ))

      llm_guardrail_result = JSON.parse(response.content.first.text)

      Result.new(
        llm_response: response.to_h,
        llm_guardrail_result: llm_guardrail_result.to_s,
        triggered: llm_guardrail_result.present?,
        guardrails: to_guardrail_hash(llm_guardrail_result),
        llm_prompt_tokens: response[:usage][:input_tokens],
        llm_completion_tokens: response[:usage][:output_tokens],
        llm_cached_tokens: response[:usage][:cache_read_input_tokens],
        model: response.model,
      )
    end

  private

    def anthropic_bedrock_client
      @anthropic_bedrock_client ||= Anthropic::BedrockClient.new(
        aws_region: ENV["CLAUDE_AWS_REGION"],
      )
    end

    def prompt
      @prompt ||= Prompt.new(llm_prompt_name)
    end

    def to_guardrail_hash(triggered_guardrail_numbers)
      prompt.guardrails.each_with_object({}) do |guardrail, guardrails_hash|
        guardrails_hash[guardrail.name.to_sym] = triggered_guardrail_numbers.include?(guardrail.key)
      end
    end

    def json_schema
      guardrail_keys = prompt.guardrails.map(&:key)
      {
        "type" => "json_schema",
        "schema" => {
          "description" => "Array of triggered guardrail numbers. Returns [] if none triggered.",
          "type" => "array",
          "items" => { "type" => "integer", "enum" => guardrail_keys },
        },
      }
    end
  end
end
