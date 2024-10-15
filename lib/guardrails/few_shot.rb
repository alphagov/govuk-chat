module Guardrails
  class FewShot
    Result = Data.define(:triggered, :guardrails, :llm_response, :llm_token_usage, :llm_guardrail_result)
    class ResponseError < StandardError
      attr_reader :llm_response, :llm_token_usage

      def initialize(message, llm_response, llm_token_usage)
        super(message)
        @llm_response = llm_response
        @llm_token_usage = llm_token_usage
      end
    end

    OPENAI_MODEL = "gpt-4o-mini".freeze
    MAX_TOKENS_BUFFER = 5

    def self.call(...) = new(...).call

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

    def response_pattern
      @response_pattern ||= begin
        guardrail_range = "[#{mapping_keys.min}-#{mapping_keys.max}]"
        /^(False \| None|True \| "#{guardrail_range}(, #{guardrail_range})*")$/
      end
    end

    def mapping_keys
      llm_prompts.dig(:few_shot, :guardrail_mappings).keys.map(&:to_i)
    end

    def extract_guardrails(parts)
      guardrail_numbers = parts.scan(/\d+/)
      mappings = llm_prompts.dig(:few_shot, :guardrail_mappings)
      guardrail_numbers.map { |n| mappings[n] }
    end

    def messages
      [
        { role: "system", content: system_prompt },
        { role: "user", content: user_prompt },
      ]
    end

    def system_prompt
      llm_prompts.dig(:few_shot, :system_prompt).gsub("{date}", Date.current.strftime("%A %d %B %Y"))
    end

    def user_prompt
      llm_prompts.dig(:few_shot, :user_prompt).sub("{input}", input)
    end

    def llm_prompts
      prompts = Rails.configuration.llm_prompts[llm_prompt_name]

      raise "No LLM prompts found for #{llm_prompt_name}" unless prompts

      prompts
    end

    def max_tokens
      all_mapping_keys = mapping_keys.map(&:to_s).join(", ")
      longest_possible_response_string = %(True | "#{all_mapping_keys}")

      token_count = Tiktoken
       .encoding_for_model(OPENAI_MODEL)
       .encode(longest_possible_response_string)
       .length

      token_count + MAX_TOKENS_BUFFER
    end
  end
end
