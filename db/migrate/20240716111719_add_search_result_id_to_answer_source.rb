class AddSearchResultIdToAnswerSource < ActiveRecord::Migration[7.1]
  def change
    change_table(:answer_sources, bulk: true) do |t|
      t.column :content_chunk_id, :string
      t.column :content_chunk_digest, :string
    end
  end
end
