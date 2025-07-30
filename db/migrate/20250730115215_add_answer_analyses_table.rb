class AddAnswerAnalysesTable < ActiveRecord::Migration[8.0]
  def change
    create_table :answer_analyses, id: :uuid do |t|
      t.string :primary_topic
      t.string :secondary_topic
      t.jsonb :metrics
      t.jsonb :llm_responses
      t.references :answer, type: :uuid, null: false, foreign_key: { on_delete: :cascade }, index: { unique: true }

      t.timestamps
    end
  end
end
