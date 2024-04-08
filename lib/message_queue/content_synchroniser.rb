module MessageQueue
  class ContentSynchroniser
    def self.call(...) = new(...).call

    def initialize(content_item)
      @content_item = content_item
    end

    # TODO: check for things already in the index
    def call
      if non_english_locale?
        return delete_with_skip_index_reason("has a non-English locale")
      end

      unless supported_schema?
        return delete_with_skip_index_reason(%(uses schema "#{schema_name}"))
      end

      if withdrawn?
        return delete_with_skip_index_reason("is withdrawn")
      end

      chunks = Chunking::ContentItemToChunks.call(content_item)
      update_opensearch(chunks)
    end

  private

    attr_reader :content_item

    def chunked_content_repository
      @chunked_content_repository ||= Search::ChunkedContentRepository.new
    end

    def delete_with_skip_index_reason(skip_index_reason)
      chunks_deleted = chunked_content_repository.delete_by_base_path(content_item["base_path"])
      Result.new(chunks_deleted:, skip_index_reason:)
    end

    def schema_name
      content_item["schema_name"]
    end

    def non_english_locale?
      content_item["locale"] != "en"
    end

    def supported_schema?
      Chunking::ContentItemToChunks.supported_schemas.include?(schema_name)
    end

    def withdrawn?
      content_item["withdrawn_notice"].present?
    end

    def update_opensearch(chunks)
      embeddings = Search::TextToEmbedding.call(chunks.map(&:plain_content))

      chunks_created = 0
      chunks_updated = 0

      chunks.each.with_index do |chunk, index|
        document = chunk.to_opensearch_hash.merge(openai_embedding: embeddings[index])
        result = chunked_content_repository.index_document(chunk.id, document)
        chunks_created += 1 if result == :created
        chunks_updated += 1 if result == :updated
      end

      Result.new(chunks_created:, chunks_updated:)
    end
  end
end
