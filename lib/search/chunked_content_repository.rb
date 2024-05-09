module Search
  class ChunkedContentRepository
    MAX_CHUNKS = 5
    MIN_SCORE = 0.5

    Result = Data.define(
      :_id,
      :score,
      :chunk_index,
      :html_content,
      :content_id,
      :heading_hierarchy,
      :digest,
      :base_path,
      :locale,
      :document_type,
      :title,
      :description,
      :url,
      :plain_content,
    )

    class NotFound < StandardError
    end

    attr_reader :index, :client, :default_refresh_writes

    def initialize
      @index = Rails.configuration.opensearch.chunked_content_index!
      @client = OpenSearch::Client.new(url: Rails.configuration.opensearch.url)
      @default_refresh_writes = Rails.configuration.opensearch.refresh_writes || false
    end

    def create_index
      client.indices.create(
        index:,
        body: {
          settings: {
            index: {
              knn: true,
            },
          },
          mappings: {
            properties: {
              content_id: { type: "keyword" },
              locale: { type: "keyword" },
              base_path: { type: "keyword" },
              document_type: { type: "keyword" },
              title: { type: "text" },
              description: { type: "text" },
              url: { type: "keyword" },
              chunk_index: { type: "keyword" },
              heading_hierarchy: { type: "text" },
              html_content: { type: "text" },
              plain_content: { type: "text" },
              openai_embedding: {
                type: "knn_vector",
                dimension: 1536, # expecting text-embedding-3-small model
                method: {
                  name: "hnsw",
                  space_type: "l2",
                  engine: "faiss",
                },
              },
              digest: { type: "keyword" },
            },
          },
        },
      )
    end

    def create_index!
      client.indices.delete(index:) if client.indices.exists?(index:)
      create_index
    end

    def count(query)
      result = client.count(index:, body: { query: })
      result["count"]
    end

    def delete_by_base_path(base_path)
      result = client.delete_by_query(
        index:,
        body: { query: { term: { base_path: } } },
        refresh: default_refresh_writes,
      )

      result["deleted"]
    end

    def delete_by_id(id_or_ids)
      result = client.delete_by_query(
        index:,
        body: { query: { ids: { values: Array(id_or_ids) } } },
        refresh: default_refresh_writes,
      )

      result["deleted"]
    end

    def index_document(id, document)
      result = client.index(index:, id:, body: document, refresh: default_refresh_writes)
      result["result"].to_sym
    end

    def id_digest_hash(base_path, batch_size: 100)
      search_body = {
        query: { term: { base_path: } },
        sort: { _id: { order: "asc" } },
        _source: { include: %w[digest] },
      }

      items = {}
      search_after = nil

      loop do
        body = search_after ? search_body.merge(search_after:) : search_body
        response = client.search(index:, size: batch_size, body:)

        total = response.dig("hits", "total", "value")
        results = response.dig("hits", "hits")

        results.each do |result|
          items[result["_id"]] = result.dig("_source", "digest")
        end

        break if results.empty? || items.count >= total

        search_after = results.last["sort"]
      end

      items
    end

    def search_by_embedding(embedding)
      response = client.search(
        index:,
        body: {
          size: MAX_CHUNKS,
          min_score: MIN_SCORE,
          query: {
            knn: {
              openai_embedding: {
                vector: embedding,
                k: MAX_CHUNKS,
              },
            },
          },
          _source: { exclude: %w[openai_embedding] },
        },
      )

      results = response.dig("hits", "hits")
      results.map do |result|
        data = { "_id" => result["_id"], "score" => result["_score"] }.merge(result["_source"])
        Result.new(**data.symbolize_keys)
      end
    end

    def chunk(id)
      response = client.get(index:, id:, _source_excludes: %w[openai_embedding])
      Result.new(**response["_source"].symbolize_keys.merge(_id: id, score: nil))
    rescue OpenSearch::Transport::Transport::Errors::NotFound
      raise NotFound, "_id: '#{id}' is not in the '#{index}' index"
    end
  end
end
