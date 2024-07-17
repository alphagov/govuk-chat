module OutputGuardrails
  class FewShot
    Result = Data.define(:triggered, :guardrails, :llm_response)
    class ResponseError < StandardError
      attr_reader :llm_response

      def initialize(message, llm_response)
        super(message)
        @llm_response = llm_response
      end
    end

    OPENAI_MODEL = "gpt-4o".freeze

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
      response_pattern = /^(False \| None|True \| "[1-7](, [1-7])*")$/

      raise ResponseError.new("Error parsing guardrail response", llm_response) unless response_pattern =~ llm_response

      parts = llm_response.split(" | ")
      triggered = parts.first.chomp == "True"
      guardrails = if triggered
                     extract_guardrails(parts.second)
                   else
                     []
                   end
      Result.new(triggered:, llm_response:, guardrails:)
    end

    def openai_response
      @openai_response ||= openai_client.chat(
        parameters: {
          model: OPENAI_MODEL,
          messages:,
          temperature: 0.0,
          max_tokens: 25,
        },
      )
    end

    def extract_guardrails(parts)
      guardrail_numbers = parts.scan(/\d+/)
      mappings = Rails.configuration.llm_prompts.guardrails.few_shot.guardrail_mappings
      guardrail_numbers.map { |n| mappings[n] }
    end

    def messages
      [
        { role: "system", content: system_prompt },
        { role: "user", content: user_prompt },
      ]
    end

    def system_prompt
      Rails.configuration.llm_prompts.guardrails.few_shot.system_prompt
        .gsub("{date}", Time.zone.today.strftime("%A %d %B %Y"))
    end

    def user_prompt
      <<~PROMPT
        Here is the answer to check: #{input}. Remember
        to return True or False and the number associated with the
        guardrail requirement if it returns True. Remember
        to carefully consider your judgement with respect to the
        instructions provided.
      PROMPT
    end
  end
end
