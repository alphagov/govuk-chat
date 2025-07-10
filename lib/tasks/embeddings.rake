namespace :embeddings do
  desc "Generate Titan embeddings for documents where the field is missing"
  task generate_titan: :environment do
    field_name = "titan_embedding"
    scroll_size = 1000
    batch_size = 10_000

    repository = Search::ChunkedContentRepository.new
    client = repository.client
    index = repository.index

    query = {
      bool: {
        must_not: [
          { exists: { field: field_name } },
        ],
      },
    }

    response = client.count(
      index:,
      body: { query: },
    )

    puts "Documents missing #{field_name} field: #{response['count']}"

    response = client.search(
      index:,
      scroll: "5m",
      body: {
        query:,
        size: scroll_size,
        _source: false,
      },
    )

    document_ids = []
    scroll_id = response["_scroll_id"]
    documents = response.dig("hits", "hits") || []

    document_ids.concat(documents.map { it["_id"] })

    while document_ids.length < batch_size && documents.any?
      response = client.scroll(
        scroll_id: scroll_id,
        scroll: "5m",
      )
      documents = response.dig("hits", "hits") || []
      break if documents.empty?

      document_ids.concat(documents.map { it["_id"] })
    end

    client.clear_scroll(scroll_id:)

    document_ids.each do |id|
      GenerateTextEmbeddingJob.perform_later(id)
    end
  end
end
