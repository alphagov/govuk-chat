module AnswerGeneration
  class OpenaiRagCompletion
    def self.call(...) = new(...).call

    def initialize(question, retriever: Retrieval::SearchApiV1Retriever)
      @question = question
      @conversation = question.conversation
      @retriever = retriever
    end

    def call
      message = retrieve_response.dig("choices", 0, "message", "content")
      question.build_answer(message:)
    end

  private

    attr_reader :question, :conversation, :retriever

    def retrieve_response
      JSON.parse(client.chat(
                   parameters: {
                     model: ENV.fetch("OPENAI_MODEL", "gpt-3.5-turbo"),
                     messages:,
                     temperature: 0.0,
                   },
                 ))
    end

    def messages
      mapped_messages.last[:content] = wrap_user_question(mapped_messages.last[:content])
      mapped_messages
    end

    def wrap_user_question(question)
      <<~PROMPT
        #{Prompts::GOVUK_DESIGNER}

        Context:
        #{context(question)}

        Question:
        #{question}
      PROMPT
    end

    def context(query)
      retriever.call(query:).join("\n")
    end

    def mapped_messages
      @mapped_messages ||= conversation.questions.map(&method(:map_question)).flatten
    end

    def map_question(question)
      return [{ role: "user", content: question.message }] if question.answer.nil?

      [
        { role: "user", content: question.message },
        { role: "assistant", content: question.answer.message },
      ]
    end

    def client
      @client ||= OpenAI::Client.new(access_token: ENV.fetch("OPENAI_ACCESS_TOKEN", "no-token-given"))
    end
  end
end
