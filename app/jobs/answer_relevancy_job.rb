class AnswerRelevancyJob < ApplicationJob
  MAX_RETRIES = 5
  retry_on Anthropic::Errors::APIError, wait: 1.minute, attempts: MAX_RETRIES

  def perform(answer_id)
    answer = Answer.includes(:analysis, question: :conversation).find_by(id: answer_id)

    return logger.warn("No answer found for #{answer_id}") unless answer
    return logger.warn("Answer #{answer_id} has already been evaluated for relevancy") if answer.analysis&.answer_relevancy_score.present?
    unless answer.eligible_for_auto_evaluation?
      return logger.info("Answer #{answer_id} is not eligible for auto evaluation")
    end

    result = AnswerAnalysisGeneration::Metrics::AnswerRelevancy.call(
      question_message: answer.rephrased_question || answer.question.message,
      answer_message: answer.message,
    )

    answer.with_lock do
      return logger.warn("Answer #{answer_id} has already been evaluated for relevancy") if answer.analysis&.answer_relevancy_score.present?

      analysis = AnswerAnalysis.find_or_initialize_by(answer_id: answer.id)
      analysis.assign_attributes(
        answer_relevancy_score: result.score,
        answer_relevancy_reason: result.reason,
      )

      result.llm_responses.stringify_keys.each do |name, llm_response|
        analysis.assign_llm_response(name, llm_response)
      end
      analysis.save!
    end
  end
end
