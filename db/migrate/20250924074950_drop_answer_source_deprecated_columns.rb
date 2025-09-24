class DropAnswerSourceDeprecatedColumns < ActiveRecord::Migration[8.0]
  def up
    change_table :answer_sources, bulk: true do |t|
      t.remove :exact_path
      t.remove :base_path
      t.remove :title
      t.remove :heading
      t.remove :content_chunk_id
      t.remove :content_chunk_digest
    end
  end

  def down
    change_table :answer_sources, bulk: true do |t|
      t.string :exact_path, null: true
      t.string :base_path, null: true
      t.string :title, null: true
      t.string :heading
      t.string :content_chunk_id, null: true
      t.string :content_chunk_digest, null: true
    end
  end
end
