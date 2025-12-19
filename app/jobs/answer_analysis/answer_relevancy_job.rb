module AnswerAnalysis
  class AnswerRelevancyJob < BaseMetricJob
    def perform(answer_id)
      return unless eligible_for_answer_analysis?(answer_id)
      return if quota_limit_reached?

      answer = Answer.includes(:question, :answer_relevancy_aggregate).find_by(id: answer_id)
      return logger.warn(aggregate_exists_warn_message(answer.id)) if answer.answer_relevancy_aggregate.present?

      results = NUMBER_OF_RUNS.times.map do
        AutoEvaluation::AnswerRelevancy.call(
          question_message: answer.rephrased_question || answer.question.message,
          answer_message: answer.message,
        )
      end

      begin
        AnswerAnalysis::AnswerRelevancyAggregate.create_mean_aggregate_and_score_runs(answer, results)
      rescue ActiveRecord::RecordNotUnique
        logger.warn(aggregate_exists_warn_message(answer.id))
      end
    end

  private

    def aggregate_exists_warn_message(answer_id)
      "Answer #{answer_id} has already been evaluated for relevancy"
    end
  end
end
