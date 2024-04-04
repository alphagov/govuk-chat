module Search
  class ChunkedContentRepository
    attr_reader :index, :client

    def initialize
      @index = Rails.configuration.opensearch.chunked_content_index!
      @client = OpenSearch::Client.new(url: Rails.configuration.opensearch.url)
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
  end
end
