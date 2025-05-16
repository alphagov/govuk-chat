class MessageQueue::ContentSynchroniser
  class IndexContentItem
    def self.call(...) = new(...).call

    def initialize(content_item, chunked_content_repository)
      @content_item = content_item
      @chunked_content_repository = chunked_content_repository
    end

    def call
      to_skip = chunks.select { |chunk| chunk.digest == id_digests[chunk.id] }
      to_index = chunks - to_skip
      chunks_created, chunks_updated = index_chunks(to_index)

      to_delete = id_digests.keys - chunks.map(&:id)
      chunks_deleted = if to_delete.any?
                         chunked_content_repository.delete_by_id(to_delete)
                       else
                         0
                       end

      Result.new(chunks_created:,
                 chunks_updated:,
                 chunks_deleted:,
                 chunks_skipped: to_skip.length)
    end

  private

    attr_reader :content_item, :chunked_content_repository

    def chunks
      @chunks ||= Chunking::ContentItemToChunks.call(content_item)
    end

    def id_digests
      @id_digests ||= chunked_content_repository.id_digest_hash(content_item["base_path"])
    end

    def index_chunks(indexable_chunks)
      openai_embeddings = Search::TextToEmbedding.call(
        indexable_chunks.map(&:plain_content), llm_provider: :openai
      )
      titan_embeddings = Search::TextToEmbedding.call(
        indexable_chunks.map(&:plain_content), llm_provider: :titan
      )

      created = 0
      updated = 0

      indexable_chunks.each.with_index do |chunk, index|
        document = chunk.to_opensearch_hash.merge(
          openai_embedding: openai_embeddings[index],
          titan_embedding: titan_embeddings[index],
        )
        result = chunked_content_repository.index_document(chunk.id, document)

        case result
        when :created
          created += 1
        when :updated
          updated += 1
        else
          raise "Unexpected index document result: #{result}"
        end
      end

      [created, updated]
    end
  end
end
