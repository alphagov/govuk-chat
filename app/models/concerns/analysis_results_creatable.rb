module AnalysisResultsCreatable
  extend ActiveSupport::Concern

  included do
    def self.create_mean_aggregate_and_score_runs(answer, results)
      mean_score = results.sum(&:score) / results.size.to_f
      aggregate = new(answer:, mean_score:)

      results.each do |result|
        run = aggregate.runs.build(
          aggregate:,
          score: result.score,
          reason: result.reason,
        )

        result.llm_responses.stringify_keys.each do |name, llm_response|
          run.assign_llm_response(name, llm_response)
        end
        result.metrics.stringify_keys.each do |name, metrics|
          run.assign_metrics(name, metrics)
        end
      end

      aggregate.save!
    end
  end
end
