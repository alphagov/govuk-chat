class AddNotNullConstraintsToAnswerSources < ActiveRecord::Migration[7.1]
  def change
    change_table :answer_sources, bulk: true do |t|
      t.change_null :content_chunk_id, false
      t.change_null :content_chunk_digest, false
      t.change_null :base_path, false
    end
  end
end
