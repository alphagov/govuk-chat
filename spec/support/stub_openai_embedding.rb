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

  # This returns a mock vector embedding which is deterministic based on the
  # text given
  def mock_openai_embedding(text, dimensions: 1536)
    random_generator = Random.new(text.bytes.sum)
    dimensions.times.map { random_generator.rand }
  end
end
