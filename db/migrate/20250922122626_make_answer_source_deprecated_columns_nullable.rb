class MakeAnswerSourceDeprecatedColumnsNullable < ActiveRecord::Migration[8.0]
  def up
    change_table :answer_sources, bulk: true do |t|
      t.change :exact_path, :string, null: true
      t.change :base_path, :string, null: true
      t.change :title, :string, null: true
      t.change :content_chunk_id, :string, null: true
      t.change :content_chunk_digest, :string, null: true
    end
  end

  def down
    change_table :answer_sources, bulk: true do |t|
      t.change :exact_path, :string, null: false
      t.change :base_path, :string, null: false
      t.change :title, :string, null: false
      t.change :content_chunk_id, :string, null: false
      t.change :content_chunk_digest, :string, null: false
    end
  end
end
