module AnswerAnalysis
  class ContextRelevancyJob < BaseJob
    EVALUATION_TYPE = "context_relevancy".freeze

    def perform(answer_id)
      return unless eligible_for_answer_analysis?(answer_id)
      return if quota_limit_reached?

      answer = Answer.includes(:question, :context_relevancy_runs).find(answer_id)
      if answer.context_relevancy_runs.present?
        return logger.warn("Answer #{answer_id} has already been evaluated for #{EVALUATION_TYPE}")
      end

      results = NUMBER_OF_RUNS.times.map { AutoEvaluation::ContextRelevancy.call(answer) }

      AnswerAnalysis::ContextRelevancyRun.create_runs_from_score_results(
        answer, results, :context_relevancy_runs
      )
    end
  end
end
