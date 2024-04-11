module AnswerComposition
  class OpenAIRagCompletion
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
      @rephrased_question = QuestionRephraser.call(question:)
      if question_contains_forbidden_words?
        question.build_answer(message: FORBIDDEN_WORDS_RESPONSE, rephrased_question:, status: "abort_forbidden_words")
      else
        message = openai_response.dig("choices", 0, "message", "content")
        question.build_answer(message:, rephrased_question:, status: "success")
      end
    rescue OpenAIClient::ContextLengthExceededError => e
      GovukError.notify(e)
      question.build_answer(
        message: AnswerComposition::Composer::UNSUCCESSFUL_REQUEST_MESSAGE,
        status: "error_context_length_exceeded",
        error_message: error_message(e),
      )
    rescue OpenAIClient::RequestError => e
      GovukError.notify(e)
      question.build_answer(
        message: AnswerComposition::Composer::UNSUCCESSFUL_REQUEST_MESSAGE,
        status: "error_answer_service_error",
        error_message: error_message(e),
      )
    end

  private

    attr_reader :question, :retriever, :openai_client, :rephrased_question

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
        { role: "user", content: rephrased_question },
      ]
    end

    def system_prompt
      <<~PROMPT
        #{Prompts::GOVUK_DESIGNER}

        Context:
        #{context(rephrased_question)}

      PROMPT
    end

    def context(query)
      retriever.call(query:).join("\n")
    end

    def question_contains_forbidden_words?
      words = rephrased_question.downcase.split(/\b/)
      Rails.configuration.question_forbidden_words.intersection(words).any?
    end

    def error_message(error)
      "class: #{error.class} message: #{error.response[:body].dig('error', 'message') || error.message}"
    end
  end
end
