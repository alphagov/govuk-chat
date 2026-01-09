module AnswerAnalysis
  class CoherenceJob < BaseJob
    EVALUATION_TYPE = "coherence".freeze

    def perform(answer_id)
      return unless eligible_for_answer_analysis?(answer_id)
      return if quota_limit_reached?

      answer = Answer.includes(:question, :coherence_runs).find(answer_id)
      if answer.coherence_runs.present?
        return logger.warn("Answer #{answer_id} has already been evaluated for #{EVALUATION_TYPE}")
      end

      results = NUMBER_OF_RUNS.times.map { AutoEvaluation::Coherence.call(answer) }

      AnswerAnalysis::CoherenceRun.create_runs_from_score_results(
        answer, results, :coherence_runs
      )
    end
  end
end
