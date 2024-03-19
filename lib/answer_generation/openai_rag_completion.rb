module AnswerGeneration
  class OpenaiRagCompletion
    def self.call(...) = new(...).call

    def initialize(question)
      @question = question
    end

    def call
      retrieve_response.dig("choices", 0, "message", "content")
    end

  private

    attr_reader :question

    delegate :conversation, to: :question

    def retrieve_response
      JSON.parse(client.chat(
                   parameters: {
                     model: ENV["OPENAI_MODEL"],
                     messages:,
                     temperature: 0.0,
                   },
                 ))
    end

    def messages
      [
        { role: "user", content: question.message },
      ]
    end

    def client
      @client ||= OpenAI::Client.new(access_token: ENV["OPENAI_ACCESS_TOKEN"])
    end
  end
end
