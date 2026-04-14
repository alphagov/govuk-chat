module Guardrails
  class MultipleChecker
    Result = Data.define(:triggered, :guardrails, :llm_response, :llm_guardrail_result,
                         :llm_prompt_tokens, :llm_completion_tokens, :llm_cached_tokens, :model) do
      def triggered_guardrails
        return [] unless guardrails

        guardrails.select { |_, v| v }.keys
      end
    end

    MAX_TOKENS = 100
    SUPPORTED_MODELS = %i[claude_sonnet_4_0 claude_haiku_4_5].freeze
    DEFAULT_MODEL = :claude_sonnet_4_0

    class ResponseError < StandardError
      attr_reader :llm_response, :llm_guardrail_result, :llm_prompt_tokens,
                  :llm_completion_tokens, :llm_cached_tokens, :model

      def initialize(message,
                     llm_response,
                     llm_guardrail_result,
                     llm_prompt_tokens,
                     llm_completion_tokens,
                     llm_cached_tokens,
                     model)
        super(message)
        @llm_response = llm_response
        @llm_guardrail_result = llm_guardrail_result
        @llm_prompt_tokens = llm_prompt_tokens
        @llm_completion_tokens = llm_completion_tokens
        @llm_cached_tokens = llm_cached_tokens
        @model = model
      end
    end

    class Prompt
      attr_reader :prompts

      Guardrail = Data.define(:key, :name, :content)

      def initialize(prompt_name)
        prompts = AnswerComposition::Pipeline::Prompts.config(
          prompt_name, Guardrails::MultipleChecker.bedrock_model
        )

        raise "No LLM prompts found for #{prompt_name}" unless prompts

        @prompts = prompts
      end

      def system_prompt
        guardrails_content = guardrails.map { |g| "#{g.key}. #{g.content}" }
                                       .join("\n")

        prompts.fetch(:system_prompt)
               .sub("{guardrails}", guardrails_content)
               .sub("{date}", Date.current.strftime("%A %d %B %Y"))
      end

      def user_prompt(input)
        prompts.fetch(:user_prompt).sub("{input}", input)
      end

      def guardrails
        @guardrails ||= prompts.fetch(:guardrails).map.with_index(1) do |name, key|
          content = prompts.fetch(:guardrail_definitions).fetch(name)
          Guardrail.new(key:, name:, content:)
        end
      end
    end

    attr_reader :input, :llm_provider, :llm_prompt_name

    def self.call(...) = new(...).call

    def self.bedrock_model
      BedrockModels.determine_model(ENV["BEDROCK_CLAUDE_GUARDRAILS_MODEL"], DEFAULT_MODEL, SUPPORTED_MODELS).last
    end

    def self.collated_prompts(llm_prompt_name)
      prompt = Prompt.new(llm_prompt_name)

      <<~PROMPT
        # System prompt

        #{prompt.system_prompt}
        # User prompt

        #{prompt.user_prompt('<insert answer to check>')}
      PROMPT
    end

    def initialize(input, llm_prompt_name)
      @input = input
      @llm_prompt_name = llm_prompt_name
    end

    def call
      response = anthropic_bedrock_client.messages.create(
        system: [{ type: "text", text: prompt.system_prompt, cache_control: { type: "ephemeral" } }],
        model: BedrockModels.model_id(self.class.bedrock_model),
        messages: [{ role: "user", content: prompt.user_prompt(input) }],
        max_tokens: MAX_TOKENS,
      )

      parse_response(response)
    end

  private

    def anthropic_bedrock_client
      @anthropic_bedrock_client ||= Anthropic::BedrockClient.new(
        aws_region: ENV["CLAUDE_AWS_REGION"],
      )
    end

    def parse_response(response)
      llm_response = response.to_h
      llm_guardrail_result = response[:content][0][:text]
      input_tokens = response[:usage][:input_tokens]
      output_tokens = response[:usage][:output_tokens]
      cache_read_input_tokens = response[:usage][:cache_read_input_tokens]
      model = response[:model]

      unless response_pattern =~ llm_guardrail_result
        raise ResponseError.new(
          "Error parsing guardrail response",
          llm_response,
          llm_guardrail_result,
          input_tokens,
          output_tokens,
          cache_read_input_tokens,
          model,
        )
      end

      parts = llm_guardrail_result.split(" | ")
      triggered = parts.first.chomp == "True"
      guardrails = to_guardrail_hash(parts.second)

      Result.new(
        llm_response:,
        llm_guardrail_result:,
        triggered:,
        guardrails:,
        llm_prompt_tokens: input_tokens,
        llm_completion_tokens: output_tokens,
        llm_cached_tokens: cache_read_input_tokens,
        model:,
      )
    end

    def prompt
      @prompt ||= Prompt.new(llm_prompt_name)
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

    def to_guardrail_hash(parts)
      triggered_guardrail_numbers = parts.scan(/\d+/).map(&:to_i)

      prompt.guardrails.each_with_object({}) do |guardrail, guardrails_hash|
        guardrails_hash[guardrail.name.to_sym] = triggered_guardrail_numbers.include?(guardrail.key)
      end
    end
  end
end
