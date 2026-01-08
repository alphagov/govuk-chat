class RemoveAnswerRelevancyAggregateAndAssociateRunsWithAnswer < ActiveRecord::Migration[8.0]
  def up
    drop_table :answer_analysis_answer_relevancy_runs
    drop_table :answer_analysis_answer_relevancy_aggregates

    create_table :answer_analysis_answer_relevancy_runs, id: :uuid do |t|
      t.decimal :score, null: false
      t.string :reason, null: false
      t.jsonb :llm_responses
      t.jsonb :metrics
      t.references :answer, type: :uuid, null: false, foreign_key: { on_delete: :cascade }
      t.timestamps
    end
  end

  def down
    drop_table :answer_analysis_answer_relevancy_runs

    create_table :answer_analysis_answer_relevancy_aggregates, id: :uuid do |t|
      t.decimal :mean_score, null: false
      t.references :answer, type: :uuid, null: false, foreign_key: { on_delete: :cascade }, index: { unique: true }
      t.timestamps
    end

    create_table :answer_analysis_answer_relevancy_runs, id: :uuid do |t|
      t.decimal :score, null: false
      t.string :reason, null: false
      t.jsonb :llm_responses
      t.jsonb :metrics
      t.references :answer_analysis_answer_relevancy_aggregate, type: :uuid, null: false, foreign_key: { on_delete: :cascade }
      t.timestamps
    end
  end
end
