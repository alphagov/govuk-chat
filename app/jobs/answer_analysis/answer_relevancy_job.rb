module AnswerAnalysis
  class AnswerRelevancyJob < BaseJob
    def perform(answer_id)
      return unless eligible_for_answer_analysis?(answer_id)
      return if quota_limit_reached?

      answer = Answer.includes(:question, :answer_relevancy_aggregate).find(answer_id)
      return logger.warn(aggregate_exists_warn_message(answer.id)) if answer.answer_relevancy_aggregate.present?

      results = NUMBER_OF_RUNS.times.map { AutoEvaluation::AnswerRelevancy.call(answer) }

      begin
        AnswerAnalysis::AnswerRelevancyRun.create_runs_from_score_results(
          answer, results, :answer_relevancy_runs
        )
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
