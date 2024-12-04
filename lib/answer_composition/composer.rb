module AnswerComposition
  class Composer
    delegate :answer_strategy, to: :question

    def self.call(...) = new(...).call

    def initialize(question)
      @question = question
    end

    def call
      start_time = Clock.monotonic_time

      compose_answer.tap do |answer|
        ForbiddenTermsChecker.call(answer)
        answer.assign_metrics("answer_composition", build_metrics(start_time))
      end
    rescue StandardError => e
      GovukError.notify(e)
      answer = question.answer || question.build_answer

      answer.assign_attributes(
        message: Answer::CannedResponses::UNSUCCESSFUL_REQUEST_MESSAGE,
        status: "error_non_specific",
        error_message: "class: #{e.class} message: #{e.message}",
      )
      answer.set_sources_as_unused
      answer.assign_metrics("answer_composition", build_metrics(start_time))
      answer
    end

  private

    attr_reader :question

    def compose_answer
      if question.conversation.user&.shadow_banned?
        return question.build_answer(
          message: Answer::CannedResponses::SHADOW_BANNED_MESSAGE,
          status: "banned",
        )
      end

      case answer_strategy
      when "openai_structured_answer"
        OpenAIAnswer.call(question:, pipeline: [
          Pipeline::JailbreakGuardrails,
          Pipeline::QuestionRephraser,
          Pipeline::QuestionRouter,
          Pipeline::QuestionRoutingGuardrails,
          Pipeline::SearchResultFetcher,
          Pipeline::OpenAIStructuredAnswerComposer,
          Pipeline::AnswerGuardrails,
        ])
      else
        raise "Answer strategy #{answer_strategy} not configured"
      end
    end

    def build_metrics(start_time)
      { duration: Clock.monotonic_time - start_time }
    end
  end
end
