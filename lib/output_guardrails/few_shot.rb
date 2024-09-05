module OutputGuardrails
  class FewShot
    Result = Data.define(:triggered, :guardrails, :llm_response, :llm_token_usage)
    class ResponseError < StandardError
      attr_reader :llm_response, :llm_token_usage

      def initialize(message, llm_response, llm_token_usage)
        super(message)
        @llm_response = llm_response
        @llm_token_usage = llm_token_usage
      end
    end

    OPENAI_MODEL = "gpt-4o-mini".freeze
    OPENAI_MAX_TOKENS = 25 # It takes 23 tokens for True | "1, 2, 3, 4, 5, 6, 7"

    def self.call(...) = new(...).call

    def initialize(input)
      @input = input
      @openai_client = OpenAIClient.build
    end

    def call
      create_result
    rescue OpenAIClient::ContextLengthExceededError => e
      raise OpenAIClient::ContextLengthExceededError.new("Exceeded context length running guardrail: #{input}", e.response)
    rescue OpenAIClient::RequestError => e
      raise OpenAIClient::RequestError.new("could not run guardrail: #{input}", e.response)
    end

  private

    attr_reader :input, :openai_client

    def create_result
      llm_response = openai_response.dig("choices", 0, "message", "content")
      llm_token_usage = openai_response["usage"]

      raise ResponseError.new("Error parsing guardrail response", llm_response, llm_token_usage) unless response_pattern =~ llm_response

      parts = llm_response.split(" | ")
      triggered = parts.first.chomp == "True"
      guardrails = if triggered
                     extract_guardrails(parts.second)
                   else
                     []
                   end
      Result.new(triggered:, llm_response:, guardrails:, llm_token_usage:)
    end

    def openai_response
      @openai_response ||= openai_client.chat(
        parameters: {
          model: OPENAI_MODEL,
          messages:,
          temperature: 0.0,
          max_tokens: OPENAI_MAX_TOKENS,
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
      Rails.configuration.llm_prompts.output_guardrails
    end
  end
end
