module Guardrails
  class MultipleChecker
    Result = Data.define(:triggered, :guardrails, :llm_response, :llm_guardrail_result,
                         :llm_prompt_tokens, :llm_completion_tokens, :llm_cached_tokens, :model) do
      def triggered_guardrails
        return [] unless guardrails

        guardrails.select { |_, v| v }.keys
      end
    end

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

      def initialize(prompt_name, llm_provider = :claude)
        prompts = if llm_provider == :claude
                    AnswerComposition::Pipeline::Claude.prompt_config(prompt_name, Claude::MultipleChecker.bedrock_model)
                  else
                    Rails.configuration.govuk_chat_private.llm_prompts[llm_provider][prompt_name]
                  end

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

    def self.collated_prompts(llm_prompt_name, llm_provider)
      prompt = Prompt.new(llm_prompt_name, llm_provider)

      <<~PROMPT
        # System prompt

        #{prompt.system_prompt}
        # User prompt

        #{prompt.user_prompt('<insert answer to check>')}
      PROMPT
    end

    def initialize(input, llm_prompt_name, llm_provider)
      @input = input
      @llm_prompt_name = llm_prompt_name
      @llm_provider = llm_provider
    end

    def call
      case llm_provider
      when :openai
        response = OpenAI::MultipleChecker.call(input, prompt)
      when :claude
        response = Claude::MultipleChecker.call(input, prompt)
      else
        raise "Unexpected provider #{llm_provider}"
      end
      parse_response(**response)
    end

  private

    def parse_response(llm_response:,
                       llm_guardrail_result:,
                       llm_prompt_tokens:,
                       llm_completion_tokens:,
                       llm_cached_tokens:,
                       model:)
      unless response_pattern =~ llm_guardrail_result
        raise ResponseError.new(
          "Error parsing guardrail response",
          llm_response,
          llm_guardrail_result,
          llm_prompt_tokens,
          llm_completion_tokens,
          llm_cached_tokens,
          model,
        )
      end

      parts = llm_guardrail_result.split(" | ")
      triggered = parts.first.chomp == "True"
      guardrails = to_guardrail_hash(parts.second)

      Result.new(
        llm_response: llm_response,
        llm_guardrail_result: llm_guardrail_result,
        triggered: triggered,
        guardrails: guardrails,
        llm_prompt_tokens: llm_prompt_tokens,
        llm_completion_tokens: llm_completion_tokens,
        llm_cached_tokens: llm_cached_tokens,
        model:,
      )
    end

    def prompt
      @prompt ||= Prompt.new(llm_prompt_name, llm_provider)
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
