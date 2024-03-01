class CreateQuestions < ActiveRecord::Migration[7.1]
  def change
    create_table :questions, id: :uuid do |t|
      t.references :conversation, type: :uuid, null: false, foreign_key: true
      t.string :message, null: false

      t.timestamps
    end

    add_index :questions, :created_at
  end
end
