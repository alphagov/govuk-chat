module AnswerComposition
  class Composer
    delegate :answer_strategy, to: :question

    def self.call(...) = new(...).call

    def initialize(question)
      @question = question
    end

    def call
      start_time = AnswerComposition.monotonic_time

      compose_answer.tap do |answer|
        answer.assign_metrics("answer_composition", {
          duration: AnswerComposition.monotonic_time - start_time,
        })
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

    def compose_answer
      case answer_strategy
      when "open_ai_rag_completion"
        OpenAIAnswer.call(question:, pipeline: [
          Pipeline::QuestionRephraser,
          Pipeline::SearchResultFetcher,
          Pipeline::OpenAIUnstructuredAnswerComposer,
          Pipeline::OutputGuardrails,
        ])
      when "openai_structured_answer"
        OpenAIAnswer.call(question:, pipeline: [
          Pipeline::QuestionRephraser,
          Pipeline::QuestionRouter,
          Pipeline::SearchResultFetcher,
          Pipeline::OpenAIStructuredAnswerComposer,
          Pipeline::OutputGuardrails,
        ])
      else
        raise "Answer strategy #{answer_strategy} not configured"
      end
    end
  end
end
