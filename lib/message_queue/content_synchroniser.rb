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
      update_opensearch(chunks)
    end

    def chunked_content_repository
      @chunked_content_repository ||= Search::ChunkedContentRepository.new
    end

  private

    attr_reader :content_item

    def update_opensearch(chunks)
      embeddings = Search::TextToEmbedding.call(chunks.map(&:plain_content))

      chunks.each.with_index do |chunk, index|
        document = chunk.to_opensearch_hash.merge(openai_embedding: embeddings[index])
        chunked_content_repository.index_document(chunk.id, document)
      end
    end
  end
end
