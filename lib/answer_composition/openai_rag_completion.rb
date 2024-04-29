module AnswerComposition
  class OpenAIRagCompletion
    FORBIDDEN_WORDS_RESPONSE = "Sorry, I can't answer that. Ask me a question about " \
      "business or trade and I'll use GOV.UK guidance to answer it.".freeze
    NO_CONTENT_FOUND_REPONSE = "Sorry, I can't find anything on GOV.UK to help me answer your question. " \
      "Could you rewrite it so I can try answering again?".freeze
    CONTEXT_LENGTH_EXCEEDED_RESPONSE = "Sorry, I can't answer that in one go. Could you make your question " \
      "simpler or more specific, or ask each part separately?".freeze
    OPENAI_CLIENT_ERROR_RESPONSE = <<~MESSAGE.freeze
      <p>Sorry, there is a problem with OpenAI's API. Try again later.</p>
      <p>We saved your conversation.</p>
      <p>Check <a href="https://www.gov.uk/browse/business">GOV.UK guidance for businesses</a> if you need information now.</p>
    MESSAGE

    OPENAI_MODEL = "gpt-3.5-turbo".freeze

    def self.call(...) = new(...).call

    def initialize(question)
      @question = question
      @openai_client = OpenAIClient.build
    end

    def call
      @question_message = QuestionRephraser.call(question:)

      return build_answer(FORBIDDEN_WORDS_RESPONSE, "abort_forbidden_words") if question_contains_forbidden_words?
      return build_answer(NO_CONTENT_FOUND_REPONSE, "abort_no_govuk_content") if search_results.blank?

      message = openai_response.dig("choices", 0, "message", "content")
      build_answer(message, "success", build_sources)
    rescue OpenAIClient::ContextLengthExceededError => e
      GovukError.notify(e)
      question.build_answer(
        message: CONTEXT_LENGTH_EXCEEDED_RESPONSE,
        status: "error_context_length_exceeded",
        error_message: error_message(e),
      )
    rescue OpenAIClient::RequestError => e
      GovukError.notify(e)
      question.build_answer(
        message: OPENAI_CLIENT_ERROR_RESPONSE,
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
        few_shots,
        { role: "user", content: question_message },
      ]
      .flatten
    end

    def system_prompt
      sprintf(llm_prompts.compose_answer.system_prompt, context:)
    end

    def rephrased_question
      question_message unless question_message == question.message
    end

    def context
      search_results.map { |result|
        [
          result.title,
          result.heading_hierarchy,
          result.description,
          result.html_content,
        ]
        .flatten
        .compact
        .join("\n")
      }
      .join("\n\n")
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

    def build_answer(message, status, sources = [])
      question.build_answer(message:, rephrased_question:, status:, sources:)
    end

    def build_sources
      result_by_base_path = search_results.group_by(&:base_path)
      result_by_base_path.map.with_index do |(base_path, group), relevancy|
        url = group.count == 1 ? group.first.url : base_path
        AnswerSource.new(url:, relevancy:)
      end
    end

    def few_shots
      llm_prompts.compose_answer.few_shots.flat_map do |few_shot|
        [
          { role: "user", content: few_shot.user },
          { role: "assistant", content: few_shot.assistant },
        ]
      end
    end

    def llm_prompts
      Rails.configuration.llm_prompts
    end
  end
end
