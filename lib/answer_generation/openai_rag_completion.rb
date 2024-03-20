module AnswerGeneration
  class OpenaiRagCompletion
    def self.call(...) = new(...).call

    def initialize(conversation)
      @conversation = conversation
    end

    def call
      retrieve_response.dig("choices", 0, "message", "content")
    end

  private

    attr_reader :conversation

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
      conversation.questions.map(&method(:map_question)).flatten
    end

    def map_question(question)
      return [{ role: "user", content: question.message }] if question.answer.nil?

      [
        { role: "user", content: question.message },
        { role: "assistant", content: question.answer.message },
      ]
    end

    def client
      @client ||= OpenAI::Client.new(access_token: ENV["OPENAI_ACCESS_TOKEN"])
    end
  end
end
