module MessageQueue
  class ContentSynchroniser
    def self.call(...) = new(...).call

    def initialize(content_item)
      @content_item = content_item
    end

    # TODO: delete redirects, gone, vanish, withdrawn schemas
    # TODO: check for things already in the index
    # TODO: create a result object for logging
    def call
      chunks = Chunking::ContentItemToChunks.call(content_item)
      documents_to_index = prepare_chunks_for_indexing(chunks)
      chunked_content_repository.bulk_index(documents_to_index:)
    end

    def chunked_content_repository
      @chunked_content_repository ||= Search::ChunkedContentRepository.new
    end

  private

    attr_reader :content_item

    def prepare_chunks_for_indexing(chunks)
      embeddings = Search::TextToEmbedding.call(chunks.map(&:plain_content))

      chunks.map.with_index do |chunk, index|
        chunk.to_opensearch_hash.merge(openai_embedding: embeddings[index])
      end
    end
  end
end
