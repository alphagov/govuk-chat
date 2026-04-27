class DropAnswerFeedback < ActiveRecord::Migration[8.0]
  def up
    drop_table :answer_feedback
  end

  def down
    create_table :answer_feedback, id: :uuid do |t|
      t.references :answer, type: :uuid, null: false, index: { unique: true }, foreign_key: { on_delete: :cascade }
      t.boolean :useful, null: false

      t.timestamps
    end

    add_index :answer_feedback, :created_at
  end
end
