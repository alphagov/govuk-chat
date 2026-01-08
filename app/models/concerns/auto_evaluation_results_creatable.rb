module AutoEvaluationResultsCreatable
  extend ActiveSupport::Concern

  class_methods do
    def create_runs_from_score_results(answer, results, association)
      transaction do
        results.each do |result|
          run = answer.public_send(association).build(
            answer:,
            score: result.score,
            reason: result.reason,
          )

          result.llm_responses.stringify_keys.each do |name, llm_response|
            run.assign_llm_response(name, llm_response)
          end
          result.metrics.stringify_keys.each do |name, metrics|
            run.assign_metrics(name, metrics)
          end

          run.save!
        end
      end
    end
  end
end
