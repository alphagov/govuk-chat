module Guardrails
  class MultipleChecker
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
        OpenAI::MultipleChecker.call(input, llm_prompt_name)
      when :claude
        Claude::MultipleChecker.call(input, llm_prompt_name)
      end
    end
  end
end
