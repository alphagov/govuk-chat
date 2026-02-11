module Search
  class ChunkedContentRepository
    Result = Data.define(
      :_id,
      :score,
      :chunk_index,
      :html_content,
      :content_id,
      :heading_hierarchy,
      :digest,
      :base_path,
      :exact_path,
      :locale,
      :document_type,
      :parent_document_type,
      :title,
      :description,
      :plain_content,
      :schema_name,
      :llm_instructions,
    ) do
      def initialize(**kwargs)
        defaults = members.index_with(nil)
        super(defaults.merge(kwargs))
      end
    end
  end
end
