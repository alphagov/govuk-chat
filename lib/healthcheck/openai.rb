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
      @message = e.message
      GovukHealthcheck::CRITICAL
    end
  end
end
