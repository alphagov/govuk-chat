module AnswerComposition
  class QuestionRephraser
    class RephrasingError < OpenAIClient::RequestError
    end

    OPENAI_MODEL = "gpt-3.5-turbo".freeze

    def self.call(...) = new(...).call

    def initialize(question:)
      @question = question
      @openai_client = OpenAIClient.build
    end

    def call
      return question.message if first_question?

      openai_response.dig("choices", 0, "message", "content")
    rescue OpenAIClient::ContextLengthExceededError => e
      raise RephrasingError.new("Exceeded context length rephrasing #{question.message}", e.response)
    rescue OpenAIClient::RequestError => e
      raise RephrasingError.new("could not rephrase #{question.message}", e.response)
    end

  private

    attr_reader :question, :openai_client

    def openai_response
      openai_client.chat(
        parameters: {
          model: OPENAI_MODEL,
          messages:,
          temperature: 0.0,
        },
      )
    end

    def messages
      [
        { role: "system", content: AnswerComposition::Prompts::QUESTION_REPHRASER },
      ] + message_history
    end

    def message_history
      question.conversation.questions.last(5).flat_map(&method(:map_question))
    end

    def map_question(question)
      return [{ role: "user", content: question.message }] if question.answer.nil?

      [
        { role: "user", content: question.message },
        { role: "assistant", content: question.answer.message },
      ]
    end

    def first_question?
      question.conversation.questions.count == 1
    end
  end
end
