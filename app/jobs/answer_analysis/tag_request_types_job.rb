module AnswerAnalysis
  class TagRequestTypesJob < BaseJob
    def perform(answer_id)
      answer = Answer.includes(:request_types, question: :conversation).find_by(id: answer_id)

      return logger.warn("No answer found for #{answer_id}") unless answer
      if answer.request_types.present?
        return logger.warn("Answer #{answer_id} has already been tagged with request types")
      end
      unless answer.eligible_for_request_type_analysis?
        return logger.info("Answer #{answer_id} is not eligible for request type analysis")
      end
      return if quota_limit_reached?

      result = AutoEvaluation::RequestTypeTagger.call(answer.question_used)

      request_types = answer.build_request_types(
        status: result.status,
        primary_request_type: result.primary_request_type,
        secondary_request_type: result.secondary_request_type,
        confidence: result.confidence,
        reasoning: result.reasoning,
        error_message: result.error_message,
      )
      request_types.assign_metrics("request_type_tagger", result.metrics)
      request_types.assign_llm_response("request_type_tagger", result.llm_response)

      request_types.save!
    end
  end
end
