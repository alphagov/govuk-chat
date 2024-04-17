module AnswerComposition
  class OpenAIRagCompletion
    FORBIDDEN_WORDS_RESPONSE = "Sorry, I can't answer that. Ask me a question about " \
      "business or trade and I'll use GOV.UK guidance to answer it.".freeze
    NO_CONTENT_FOUND_REPONSE = "Sorry, I can't find anything on GOV.UK to help me answer your question. " \
      "Could you rewrite it so I can try answering again?".freeze

    OPENAI_MODEL = "gpt-3.5-turbo".freeze

    def self.call(...) = new(...).call

    def initialize(question)
      @question = question
      @retriever = Retrieval::SearchApiV1Retriever
      @openai_client = OpenAIClient.build
    end

    def call
      @question_message = QuestionRephraser.call(question:)

      return build_answer(FORBIDDEN_WORDS_RESPONSE, "abort_forbidden_words") if question_contains_forbidden_words?
      return build_answer(NO_CONTENT_FOUND_REPONSE, "abort_no_govuk_content") if search_results.blank?

      message = openai_response.dig("choices", 0, "message", "content")
      question.build_answer(message:, rephrased_question:, status: "success")
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

    attr_reader :question, :retriever, :openai_client, :question_message

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
        { role: "user", content: question_message },
      ]
    end

    def system_prompt
      <<~PROMPT
        #{Prompts::GOVUK_DESIGNER}

        Context:
        #{context}

      PROMPT
    end

    def rephrased_question
      question_message unless question_message == question.message
    end

    def context
      search_results.map(&:html_content).join("\n")
    end

    def question_contains_forbidden_words?
      words = question_message.downcase.split(/\b/)
      Rails.configuration.question_forbidden_words.intersection(words).any?
    end

    def error_message(error)
      "class: #{error.class} message: #{error.response[:body].dig('error', 'message') || error.message}"
    end

    def search_results
      @search_results ||= Search::ResultsForQuestion.call(question_message)
    end

    def build_answer(message, status, sources = nil)
      question.build_answer(message:, rephrased_question:, status:, sources:)
    end
  end
end
