module AnswerComposition
  class Composer
    delegate :answer_strategy, to: :question

    def self.call(...) = new(...).call

    def initialize(question)
      @question = question
    end

    def call
      case answer_strategy
      when "open_ai_rag_completion"
        OpenAIAnswer.call(question:, pipeline: [
          Pipeline::QuestionRephraser,
          Pipeline::ForbiddenWordsChecker,
          Pipeline::SearchResultFetcher,
          Pipeline::OpenAIUnstructuredAnswerComposer,
          Pipeline::OutputGuardrails,
        ])
      when "openai_structured_answer"
        OpenAIAnswer.call(question:, pipeline: [
          Pipeline::QuestionRephraser,
          Pipeline::ForbiddenWordsChecker,
          Pipeline::QuestionRouter,
          Pipeline::SearchResultFetcher,
          Pipeline::OpenAIStructuredAnswerComposer,
          Pipeline::OutputGuardrails,
        ])
      else
        raise "Answer strategy #{answer_strategy} not configured"
      end
    rescue StandardError => e
      GovukError.notify(e)
      question.build_answer(
        message: Answer::CannedResponses::UNSUCCESSFUL_REQUEST_MESSAGE,
        status: "error_non_specific",
        error_message: "class: #{e.class} message: #{e.message}",
      )
    end

  private

    attr_reader :question
  end
end
