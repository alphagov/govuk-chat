module MessageQueue
  class ContentSynchroniser
    Result = Data.define(:chunks_created, :chunks_updated) do
      include ActionView::Helpers::TextHelper

      def initialize(chunks_created: 0, chunks_updated: 0)
        super
      end

      def to_s
        "#{pluralize(chunks_created, 'chunk')} newly inserted, #{pluralize(chunks_updated, 'chunk')} updated"
      end
    end

    def self.call(...) = new(...).call

    def initialize(content_item)
      @content_item = content_item
    end

    # TODO: delete redirects, gone, vanish, withdrawn schemas
    # TODO: check for things already in the index
    def call
      chunks = Chunking::ContentItemToChunks.call(content_item)
      update_opensearch(chunks)
    end

  private

    attr_reader :content_item

    def chunked_content_repository
      @chunked_content_repository ||= Search::ChunkedContentRepository.new
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
