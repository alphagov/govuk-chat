module AnswerAnalysis
  class FaithfulnessJob < BaseJob
    EVALUATION_TYPE = "faithfulness".freeze

    def perform(answer_id)
      return unless eligible_for_answer_analysis?(answer_id)
      return if quota_limit_reached?

      answer = Answer.includes(:question, { sources: :chunk }, :faithfulness_runs).find(answer_id)
      if answer.faithfulness_runs.present?
        return logger.warn("Answer #{answer_id} has already been evaluated for #{EVALUATION_TYPE}")
      end

      results = NUMBER_OF_RUNS.times.map { AutoEvaluation::Faithfulness.call(answer) }

      AnswerAnalysis::FaithfulnessRun.create_runs_from_score_results(
        answer, results, :faithfulness_runs
      )
    end
  end
end
