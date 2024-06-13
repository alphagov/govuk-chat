class CreateAnswerFeedbackTable < ActiveRecord::Migration[7.1]
  def change
    create_table :answer_feedback, id: :uuid do |t|
      t.references :answer, type: :uuid, null: false, index: { unique: true }, foreign_key: { on_delete: :cascade }
      t.boolean :useful, null: false

      t.timestamps
    end

    add_index :answer_feedback, :created_at
  end
end
