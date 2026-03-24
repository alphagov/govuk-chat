class DefaultMetricsAndLlmResponsesColumnsToEmptyHash < ActiveRecord::Migration[8.0]
  TABLES = %i[
    answers
    answer_analysis_answer_relevancy_runs
    answer_analysis_coherence_runs
    answer_analysis_context_relevancy_runs
    answer_analysis_faithfulness_runs
    answer_analysis_topics
  ].freeze

  def up
    TABLES.each do |table|
      change_table table, bulk: true do |t|
        t.change_default :metrics, {}
        t.change_default :llm_responses, {}
      end
    end
  end

  def down
    TABLES.each do |table|
      change_table table, bulk: true do |t|
        t.change_default :metrics, nil
        t.change_default :llm_responses, nil
      end
    end
  end
end
