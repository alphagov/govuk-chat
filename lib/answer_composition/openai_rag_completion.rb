module AnswerComposition
  class OpenaiRagCompletion
    FORBIDDEN_WORDS_RESPONSE = "Sorry, I can't answer that. Ask me a question about " \
      "business or trade and I'll use GOV.UK guidance to answer it.".freeze

    OPENAI_MODEL = "gpt-3.5-turbo".freeze

    def self.call(...) = new(...).call

    def initialize(question)
      @question = question
      @retriever = Retrieval::SearchApiV1Retriever
      @openai_client = OpenAIClient.build
    end

    def call
      if question_contains_forbidden_words?
        # TODO: add the status when we have it in the db
        question.build_answer(message: FORBIDDEN_WORDS_RESPONSE)
      else
        message = openai_response.dig("choices", 0, "message", "content")
        question.build_answer(message:, status: "success")
      end
    end

  private

    attr_reader :question, :retriever, :openai_client

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
        { role: "system", content: system_prompt },
        { role: "user", content: question.message },
      ]
    end

    def system_prompt
      <<~PROMPT
        #{Prompts::GOVUK_DESIGNER}

        Context:
        #{context(question)}

      PROMPT
    end

    def context(query)
      retriever.call(query:).join("\n")
    end

    def question_contains_forbidden_words?
      words = question.message.downcase.split(/\b/)
      Rails.configuration.question_forbidden_words.intersection(words).any?
    end
  end
end
