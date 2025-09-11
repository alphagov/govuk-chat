class CreateAnswerSourceChunksTable < ActiveRecord::Migration[8.0]
  def change
    create_table :answer_source_chunks, id: :uuid do |t|
      t.uuid :content_id, null: false
      t.string :locale, null: false
      t.integer :chunk_index, null: false
      t.string :digest, null: false

      t.string :title, null: false
      t.string :description
      t.string :heading_hierachy, array: true

      t.string :base_path, null: false
      t.string :exact_path, null: false

      t.string :document_type, null: false
      t.string :parent_document_type

      t.string :html_content, null: false
      t.string :plain_content, null: false

      t.timestamps

      t.index %i[content_id locale chunk_index digest], unique: true
    end
  end
end
