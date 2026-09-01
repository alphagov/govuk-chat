class CreateAnswerFeedback < ActiveRecord::Migration[8.1]
  def change
    create_enum :answer_feedback_reaction, %w[positive negative]

    create_table :answer_feedback, id: :uuid do |t|
      t.references :answer, type: :uuid, null: false, index: { unique: true }, foreign_key: { on_delete: :cascade }
      t.enum :reaction, null: false, enum_type: "answer_feedback_reaction"

      t.timestamps
    end

    add_index :answer_feedback, :created_at
  end
end
