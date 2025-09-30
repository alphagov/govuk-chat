module Healthcheck
  class OpenAI
    attr_reader :message

    def name
      :openai
    end

    def status
      client = OpenAIClient.build
      client.models.list
      GovukHealthcheck::OK
    rescue StandardError => e
      @message = "Listing OpenAI models failed with a #{e.class} error"
      GovukHealthcheck::CRITICAL
    end

    def enabled?
      Rails.configuration.answer_strategy == "openai_structured_answer"
    end
  end
end
