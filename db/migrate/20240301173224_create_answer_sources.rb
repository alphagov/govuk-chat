class CreateAnswerSources < ActiveRecord::Migration[7.1]
  def change
    create_table :answer_sources, id: :uuid do |t|
      t.references :answer, type: :uuid, null: false, foreign_key: true
      t.string :url, null: false

      t.timestamps
    end

    add_index :answer_sources, :created_at
  end
end
