module AnswerAnalysis
  class AnswerRelevancyJob < BaseJob
    EVALUATION_TYPE = "answer_relevancy".freeze

    def perform(answer_id)
      return unless eligible_for_answer_analysis?(answer_id)
      return if quota_limit_reached?

      answer = Answer.includes(:question, :answer_relevancy_runs).find(answer_id)
      if answer.answer_relevancy_runs.present?
        return logger.warn("Answer #{answer_id} has already been evaluated for #{EVALUATION_TYPE}")
      end

      results = NUMBER_OF_RUNS.times.map { AutoEvaluation::AnswerRelevancy.call(answer) }

      AnswerAnalysis::AnswerRelevancyRun.create_runs_from_score_results(
        answer, results, :answer_relevancy_runs
      )
    end
  end
end
