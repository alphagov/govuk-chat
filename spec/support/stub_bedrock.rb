module StubBedrock
  TITAN_EMBEDDING_ENDPOINT_REGEX = %r{https://bedrock-runtime\..*\.amazonaws\.com/model/.*titan-embed-text.*?/invoke}

  def stub_bedrock_invoke_model_response(request_body:, response_body:)
    stub_request(:post, TITAN_EMBEDDING_ENDPOINT_REGEX)
      .with(body: request_body)
      .to_return_json(
        status: 200,
        body: response_body,
        headers: { "Content-Type" => "application/json" },
      )
  end

  def stub_bedrock_invoke_model_response_with_error(request_body:, error:)
    stub_request(:post, TITAN_EMBEDDING_ENDPOINT_REGEX)
      .with(body: request_body)
      .to_raise(error)
  end

  def stub_bedrock_titan_invoke_error(input_text, error_message)
    stub_bedrock_invoke_model_response_with_error(
      request_body: { inputText: input_text }.to_json,
      error: Aws::BedrockRuntime::Errors::ValidationException.new({}, error_message),
    )
  end

  def stub_bedrock_titan_embedding(text)
    stub_bedrock_invoke_model_response(
      request_body: { inputText: text }.to_json,
      response_body: bedrock_titan_embedding_response(mock_titan_embedding(text)),
    )
  end

  def bedrock_titan_embedding_response(embedding_array)
    {
      embedding: embedding_array,
    }.to_json
  end

  def mock_titan_embedding(text, dimensions: Search::ChunkedContentRepository::TITAN_EMBEDDING_DIMENSIONS)
    # This returns a mock vector embedding which is deterministic based on the
    # text given
    random_generator = Random.new(text.bytes.sum)
    dimensions.times.map { random_generator.rand }
  end
end
