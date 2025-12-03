module StubBedrock
  def stub_bedrock_invoke_model(*responses)
    bedrock_client = Aws::BedrockRuntime::Client.new(stub_responses: true)
    allow(Aws::BedrockRuntime::Client).to receive(:new).and_return(bedrock_client)
    bedrock_client.stub_responses(:invoke_model, responses)
    bedrock_client
  end

  def stub_bedrock_titan_embedding(text = "text")
    stub_bedrock_invoke_model(
      bedrock_titan_embedding_response(mock_titan_embedding(text)),
    )
  end

  def bedrock_titan_embedding_response(embedding_array)
    {
      content_type: "application/json",
      body: {
        embedding: embedding_array,
      }.to_json,
    }
  end

  def mock_titan_embedding(text, dimensions: Search::ChunkedContentRepository::TITAN_EMBEDDING_DIMENSIONS)
    # This returns a mock vector embedding which is deterministic based on the
    # text given
    random_generator = Random.new(text.bytes.sum)
    dimensions.times.map { random_generator.rand }
  end

  def stub_bedrock_converse(*responses)
    bedrock_client = Aws::BedrockRuntime::Client.new(stub_responses: true)
    allow(Aws::BedrockRuntime::Client).to receive(:new).and_return(bedrock_client)
    bedrock_client.stub_responses(:converse, responses)
    bedrock_client
  end

  def bedrock_converse_client_response(content:)
    text_content_block = Aws::BedrockRuntime::Types::ContentBlock::Text.new(text: content)
    message = Aws::BedrockRuntime::Types::Message.new(
      role: "assistant",
      content: [text_content_block],
    )
    output = Aws::BedrockRuntime::Types::ConverseOutput::Message.new(message:)
    usage = Aws::BedrockRuntime::Types::TokenUsage.new(
      input_tokens: 25,
      output_tokens: 35,
      total_tokens: 60,
    )
    metrics = Aws::BedrockRuntime::Types::ConverseMetrics.new(latency_ms: 2000)
    Aws::BedrockRuntime::Types::ConverseResponse.new(
      output:,
      usage:,
      stop_reason: "end_turn",
      metrics:,
    )
  end
end
