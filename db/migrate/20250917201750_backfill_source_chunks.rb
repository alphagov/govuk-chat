class BackfillSourceChunks < ActiveRecord::Migration[8.0]
  class AnswerSource < ApplicationRecord; end
  class AnswerSourceChunk < ApplicationRecord; end

  disable_ddl_transaction!

  def up
    AnswerSource.where(answer_source_chunk_id: nil).find_each do |answer_source|
      content_id, locale, chunk_index = answer_source.content_chunk_id.split("_")
      attributes = {
        content_id:,
        locale:,
        chunk_index:,
        digest: answer_source.content_chunk_digest,
        title: answer_source.title,
        base_path: answer_source.base_path,
        exact_path: answer_source.exact_path,
        # There isn't sufficient data for these fields so we're making do
        heading_hierarchy: [answer_source.heading].compact,
        document_type: "",
        html_content: "",
        plain_content: "",
      }

      unique_attributes = attributes.slice(:content_id, :locale, :chunk_index, :digest)
      chunk = AnswerSourceChunk.find_or_create_by!(unique_attributes) do |to_insert|
        to_insert.attributes = attributes
      end

      answer_source.update!(answer_source_chunk_id: chunk.id)
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigratio
  end
end
