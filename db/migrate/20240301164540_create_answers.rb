class CreateAnswers < ActiveRecord::Migration[7.1]
  def change
    create_table :answers, id: :uuid do |t|
      t.references :question, type: :uuid, null: false, foreign_key: true
      t.string :message, null: false
      t.string :rephrased_question

      t.timestamps
    end

    add_index :answers, :created_at
  end
end
