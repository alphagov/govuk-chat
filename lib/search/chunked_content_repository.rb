module Search
  class ChunkedContentRepository
    OPENAI_EMBEDDING_DIMENSIONS = 3072
    MAPPINGS = {
      content_id: { type: "keyword" },
      locale: { type: "keyword" },
      base_path: { type: "keyword" },
      document_type: { type: "keyword" },
      parent_document_type: { type: "keyword" },
      title: { type: "text" },
      description: { type: "text" },
      url: { type: "keyword" }, # TODO: rename this to exact_path to match our answer sources
      chunk_index: { type: "keyword" },
      heading_hierarchy: { type: "text" },
      html_content: { type: "text" },
      plain_content: { type: "text" },
      openai_embedding: {
        type: "knn_vector",
        dimension: OPENAI_EMBEDDING_DIMENSIONS,
        method: {
          name: "hnsw",
          space_type: "cosinesimil",
          engine: "nmslib",
        },
      },
      digest: { type: "keyword" },
    }.freeze

    class NotFound < StandardError
    end

    attr_reader :index, :default_index_name, :client, :default_refresh_writes

    def initialize
      @index = Rails.configuration.opensearch.chunked_content_index!
      @default_index_name = Rails.configuration.opensearch.chunked_content_default_index!
      client_options = Rails.configuration.opensearch.slice(:url, :user, :password)
      @client = OpenSearch::Client.new(**client_options)
      @default_refresh_writes = Rails.configuration.opensearch.refresh_writes || false
    end

    def create_index(index_name: default_index_name, create_alias: true)
      aliases = create_alias ? { index.to_sym => {} } : {}
      client.indices.create( # rubocop:disable Rails/SaveBang
        index: index_name,
        body: {
          settings: {
            index: {
              knn: true,
            },
          },
          mappings: {
            properties: MAPPINGS,
          },
          aliases:,
        },
      )
    end

    def create_index!(index_name: default_index_name, create_alias: true)
      client.indices.delete(index: index_name) if client.indices.exists?(index: index_name)
      create_index(index_name:, create_alias:)
    end

    def count(query)
      result = client.count(index:, body: { query: })
      result["count"]
    end

    def update_missing_mappings
      index_details = client.indices.get_mapping(index:).values.first
      opensearch_mappings = index_details.dig("mappings", "properties").to_h.symbolize_keys

      missing_keys = MAPPINGS.keys - opensearch_mappings.keys

      return [] if missing_keys.empty?

      missing_mappings = MAPPINGS.slice(*missing_keys)

      client.indices.put_mapping(
        index:,
        body: {
          properties: missing_mappings,
        },
      )

      missing_keys
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

    def search_by_embedding(embedding, max_chunks:)
      response = client.search(
        index:,
        body: {
          size: max_chunks,
          query: {
            knn: {
              openai_embedding: {
                vector: embedding,
                k: max_chunks,
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
      Result.new(**response["_source"].symbolize_keys.merge(_id: id))
    rescue OpenSearch::Transport::Transport::Errors::NotFound
      raise NotFound, "_id: '#{id}' is not in the '#{index}' index"
    end
  end
end
