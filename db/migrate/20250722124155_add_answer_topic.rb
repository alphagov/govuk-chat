class AddAnswerTopic < ActiveRecord::Migration[8.0]
  def change
    create_table :answer_topics, id: :uuid do |t|
      t.string :primary, null: false
      t.string :secondary
      t.jsonb :metrics
      t.jsonb :llm_response
      t.references :answer, type: :uuid, null: false, foreign_key: { on_delete: :cascade }

      t.timestamps
    end
  end
end
