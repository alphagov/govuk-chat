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

      results = NUMBER_OF_RUNS.times.map do
        if Rails.configuration.answer_strategy == "non_llm_answer"
          # Temporary strategy for SREs to load test without incurring LLM costs
          sleep 10
          AutoEvaluation::Result.new(
            status: "success",
            score: 1.0,
            reason: "reason",
            llm_responses: {},
            metrics: {},
          )
        else
          AutoEvaluation::Faithfulness.call(answer)
        end
      end

      AnswerAnalysis::FaithfulnessRun.create_runs_from_auto_evaluation_results(
        answer, results, :faithfulness_runs
      )
    end
  end
end
