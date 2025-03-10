module Guardrails
  class MultipleChecker
    MAX_TOKENS_BUFFER = 5

    Result = Data.define(:triggered, :guardrails, :llm_response, :llm_token_usage, :llm_guardrail_result)
    class ResponseError < StandardError
      attr_reader :llm_response, :llm_token_usage

      def initialize(message, llm_response, llm_token_usage)
        super(message)
        @llm_response = llm_response
        @llm_token_usage = llm_token_usage
      end
    end

    class Prompt
      attr_reader :prompts

      Guardrail = Data.define(:key, :name, :content)

      def initialize(prompt_name, llm_provider = :openai)
        prompts = Rails.configuration.govuk_chat_private.llm_prompts[llm_provider][prompt_name]

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
      end
      parse_response(**response)
    end

  private

    def parse_response(llm_response:, llm_guardrail_result:, llm_token_usage:)
      unless response_pattern =~ llm_guardrail_result
        raise ResponseError.new(
          "Error parsing guardrail response", llm_guardrail_result, llm_token_usage
        )
      end

      parts = llm_guardrail_result.split(" | ")
      triggered = parts.first.chomp == "True"
      guardrails = triggered ? extract_guardrails(parts.second) : []

      Result.new(
        llm_response: llm_response,
        llm_guardrail_result: llm_guardrail_result,
        triggered: triggered,
        guardrails: guardrails,
        llm_token_usage: llm_token_usage,
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

    def extract_guardrails(parts)
      guardrail_numbers = parts.scan(/\d+/).map(&:to_i)
      prompt.guardrails.select { |guardrail| guardrail.key.in?(guardrail_numbers) }.map(&:name)
    end
  end
end
