class AnswerSourceChunk < ApplicationRecord
  def self.find_or_create_from_search_result(search_result)
    attributes = search_result.to_h.slice(:content_id,
                                          :locale,
                                          :chunk_index,
                                          :digest,
                                          :title,
                                          :description,
                                          :heading_hierarchy,
                                          :base_path,
                                          :exact_path,
                                          :document_type,
                                          :parent_document_type,
                                          :html_content,
                                          :plain_content)

    unique_attributes = attributes.slice(:content_id, :locale, :chunk_index, :digest)

    find_or_create_by!(unique_attributes) do |chunk|
      chunk.assign_attributes(attributes)
    end
  end

  def govuk_url
    "#{Plek.website_root}#{exact_path}"
  end

  def heading
    heading_hierarchy.last
  end

  def serialize_for_export
    as_json.merge("chunk_uid" => "#{content_id}_#{locale}_#{chunk_index}_#{digest}")
  end
end
