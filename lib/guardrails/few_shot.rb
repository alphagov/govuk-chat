module Guardrails
  class FewShot
    OPENAI_MODEL = "gpt-4o".freeze

    def self.call(...) = new(...).call

    def initialize(input)
      @input = input
      @openai_client = OpenAIClient.build
    end

    def call
      openai_response.dig("choices", 0, "message", "content")
    rescue OpenAIClient::ContextLengthExceededError => e
      Rails.logger.error("Exceeded context length running guardrail: #{e.message}")
      raise OpenAIClient::ContextLengthExceededError.new("Exceeded context length running guardrail: #{input}", e.response)
    rescue OpenAIClient::RequestError => e
      Rails.logger.error("OpenAI error running guardrail: #{e.message}")
      raise OpenAIClient::RequestError.new("could not run guardrail: #{input}", e.response)
    end

  private

    attr_reader :input, :openai_client

    def openai_response
      @openai_response ||= openai_client.chat(
        parameters: {
          model: OPENAI_MODEL,
          messages:,
          temperature: 0.0,
          max_tokens: 1,
        },
      )
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
