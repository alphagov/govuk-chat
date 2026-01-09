class AddAnswerAnalysisCoherenceTables < ActiveRecord::Migration[8.0]
  def change
    create_table :answer_analysis_coherence_runs, id: :uuid do |t|
      t.decimal :score, null: false
      t.string :reason, null: false
      t.jsonb :llm_responses
      t.jsonb :metrics
      t.references :answer, type: :uuid, null: false, foreign_key: { on_delete: :cascade }
      t.timestamps
    end
  end
end
