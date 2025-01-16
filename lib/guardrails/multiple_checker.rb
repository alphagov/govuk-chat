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

      def initialize(prompt_name)
        prompts = Rails.configuration.govuk_chat_private.llm_prompts[prompt_name]
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

    OPENAI_MODEL = "gpt-4o-mini".freeze
    MAX_TOKENS_BUFFER = 5

    def self.call(...) = new(...).call

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
      @openai_client = OpenAIClient.build
      @llm_prompt_name = llm_prompt_name
    end

    def call
      llm_response = openai_response.dig("choices", 0)
      llm_guardrail_result = llm_response.dig("message", "content")
      llm_token_usage = openai_response["usage"]

      unless response_pattern =~ llm_guardrail_result
        raise ResponseError.new(
          "Error parsing guardrail response", llm_guardrail_result, llm_token_usage
        )
      end

      parts = llm_guardrail_result.split(" | ")
      triggered = parts.first.chomp == "True"
      guardrails = if triggered
                     extract_guardrails(parts.second)
                   else
                     []
                   end
      Result.new(triggered:, llm_response:, guardrails:, llm_token_usage:, llm_guardrail_result:)
    end

  private

    attr_reader :input, :openai_client, :llm_prompt_name

    def openai_response
      @openai_response ||= openai_client.chat(
        parameters: {
          model: OPENAI_MODEL,
          messages:,
          temperature: 0.0,
          max_tokens:,
        },
      )
    end

    def messages
      [
        { role: "system", content: prompt.system_prompt },
        { role: "user", content: prompt.user_prompt(input) },
      ]
    end

    def prompt
      @prompt ||= Prompt.new(llm_prompt_name)
    end

    def max_tokens
      all_guardrail_numbers = guardrail_numbers.map(&:to_s).join(", ")
      longest_possible_response_string = %(True | "#{all_guardrail_numbers}")

      token_count = Tiktoken
       .encoding_for_model(OPENAI_MODEL)
       .encode(longest_possible_response_string)
       .length

      token_count + MAX_TOKENS_BUFFER
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
