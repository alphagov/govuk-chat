module StubOpenAIEmbedding
  def stub_openai_embedding(input)
    model = "text-embedding-3-small"
    input = Array(input)
    data = input.map.with_index do |text, index|
      { object: "embedding", embedding: mock_openai_embedding(text), index: }
    end

    stub_request(:post, "https://api.openai.com/v1/embeddings")
      .with(body: { input:, model: })
      .to_return_json(status: 200, body: { object: "list", data:, model: })
  end

  # Setting lots of embeddings allows dealing with chunked content of variable lengths
  def stub_any_openai_embedding(embeddings_per_request: 20)
    data = embeddings_per_request.times.map do |index|
      query = "Query #{index + 1}"
      { object: "embedding", embedding: mock_openai_embedding(query), index: }
    end

    stub_request(:post, "https://api.openai.com/v1/embeddings")
      .to_return_json(
        status: 200,
        body: {
          object: "list",
          data:,
          model: "text-3-embedding-small",
        },
      )
  end

  # This returns a mock vector embedding which is deterministic based on the
  # text given
  def mock_openai_embedding(text, dimensions: 1536)
    random_generator = Random.new(text.bytes.sum)
    dimensions.times.map { random_generator.rand }
  end

  # this returns a vector that is a fixed distance from the embedding parameter
  # The score is always 0.435898
  def close_openai_embedding(embedding)
    embedding.map { |n| n * 1.05 }
  end
end
