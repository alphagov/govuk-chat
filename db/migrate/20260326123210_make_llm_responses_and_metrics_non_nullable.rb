class MakeLlmResponsesAndMetricsNonNullable < ActiveRecord::Migration[8.0]
  TABLES = %i[
    answers
    answer_analysis_answer_relevancy_runs
    answer_analysis_coherence_runs
    answer_analysis_context_relevancy_runs
    answer_analysis_faithfulness_runs
    answer_analysis_topics
  ].freeze

  def change
    TABLES.each do |table|
      change_table table, bulk: true do |t|
        t.change_null :metrics, false
        t.change_null :llm_responses, false
      end
    end
  end
end
