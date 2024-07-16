module AnswerComposition
  class OpenAIUnstructuredAnswer < OpenAIAnswer
    OPENAI_MODEL = "gpt-3.5-turbo".freeze

    def self.call(...) = new(...).call

    def call
      answer_pipeline(
        Pipeline::QuestionRephraser,
        # Pipeline::ForbiddenWordsChecker,
        # Pipeline::SearchResultFetcher,
        # method(:compose_answer)
      )

      # return build_answer(Answer::CannedResponses::FORBIDDEN_WORDS_RESPONSE, "abort_forbidden_words") if question_contains_forbidden_words?
      # return build_answer(Answer::CannedResponses::NO_CONTENT_FOUND_REPONSE, "abort_no_govuk_content") if search_results.blank?

      # message = openai_response.dig("choices", 0, "message", "content")
      # build_answer(message, "success", build_sources)
    end

  private

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
        { role: "user", content: context.question_message },
      ]
      .flatten
    end

    def system_prompt
      sprintf(llm_prompts.answer_composition.compose_answer.system_prompt, context: system_prompt_context)
    end

    def system_prompt_context
      context.search_results.map { |result|
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

    # def question_contains_forbidden_words?
    #   words = question_message.downcase.split(/\b/)
    #   Rails.configuration.question_forbidden_words.intersection(words).any?
    # end

    def search_results
      @search_results ||= Search::ResultsForQuestion.call(context.question_message).results
    end

    # def build_answer(message, status, sources = [])
    #   question.build_answer(message:, rephrased_question:, status:, sources:)
    # end

    # def build_sources
    #   search_results.map.with_index do |result, relevancy|
    #     AnswerSource.new(
    #       exact_path: result.url,
    #       base_path: result.base_path,
    #       title: result.title,
    #       relevancy:,
    #       content_chunk_id: result._id,
    #       content_chunk_digest: result.digest,
    #       heading: result.heading_hierarchy.last,
    #     )
    #   end
    # end

    def few_shots
      llm_prompts.answer_composition.compose_answer.few_shots.flat_map do |few_shot|
        [
          { role: "user", content: few_shot.user },
          { role: "assistant", content: few_shot.assistant },
        ]
      end
    end

    def llm_prompts
      Rails.configuration.llm_prompts
    end

    def openai_client
      @openai_client ||= OpenAIClient.build
    end
  end
end
