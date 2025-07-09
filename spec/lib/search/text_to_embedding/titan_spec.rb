RSpec.describe Search::TextToEmbedding::Titan do
  describe ".call" do
    it "returns a single embedding array for a string input" do
      client = stub_bedrock_invoke_model(
        bedrock_titan_embedding_response([1.0, 2.0, 3.0]),
      )

      embedding = described_class.call("text")

      expect(client.api_requests.size).to eq(1)

      expect(embedding).to eq([1.0, 2.0, 3.0])
    end

    it "returns an array of embedding arrays for an array input" do
      client = stub_bedrock_invoke_model(
        bedrock_titan_embedding_response([1.0, 2.0, 3.0]),
        bedrock_titan_embedding_response([4.0, 5.0, 6.0]),
      )

      embedding = described_class.call(["Embed this", "Embed that"])

      expect(client.api_requests.size).to eq(2)

      expect(embedding).to eq([[1.0, 2.0, 3.0], [4.0, 5.0, 6.0]])
    end

    it "truncates input text to the character length limit" do
      client = stub_bedrock_titan_embedding

      long_text = "a" * (described_class::INPUT_TEXT_LENGTH_LIMIT + 1)
      described_class.call(long_text)

      expect(client.api_requests.size).to eq(1)

      request_body = JSON.parse(
        client.api_requests.first.dig(:params, :body),
      )

      expect(request_body["inputText"].length)
        .to eq(described_class::INPUT_TEXT_LENGTH_LIMIT)
    end

    it "retries embedding generation if the input exceeds the token limit" do
      client = Aws::BedrockRuntime::Client.new(stub_responses: true)
      allow(Aws::BedrockRuntime::Client).to receive(:new).and_return(client)
      client.stub_responses(
        :invoke_model,
        [
          Aws::BedrockRuntime::Errors::ValidationException.new({}, "400 Bad Request: Too many input tokens."),
          Aws::BedrockRuntime::Errors::ValidationException.new({}, "400 Bad Request: Too many input tokens."),
          bedrock_titan_embedding_response([1.0, 2.0, 3.0]),
        ],
      )

      long_text = "a" * described_class::INPUT_TEXT_LENGTH_LIMIT
      described_class.call(long_text)

      expect(client.api_requests.size).to eq(3)

      request_input_text_lengths = client.api_requests.map do |request|
        JSON.parse(request.dig(:params, :body))["inputText"].length
      end

      expect(request_input_text_lengths).to eq([50_000, 40_000, 32_000])
    end

    it "raises an error if embedding generation fails after max number of retries" do
      client = Aws::BedrockRuntime::Client.new(stub_responses: true)
      allow(Aws::BedrockRuntime::Client).to receive(:new).and_return(client)
      client.stub_responses(
        :invoke_model,
        [
          Aws::BedrockRuntime::Errors::ValidationException.new({}, "400 Bad Request: Too many input tokens."),
          Aws::BedrockRuntime::Errors::ValidationException.new({}, "400 Bad Request: Too many input tokens."),
          Aws::BedrockRuntime::Errors::ValidationException.new({}, "400 Bad Request: Too many input tokens."),
          Aws::BedrockRuntime::Errors::ValidationException.new({}, "400 Bad Request: Too many input tokens."),
          Aws::BedrockRuntime::Errors::ValidationException.new({}, "400 Bad Request: Too many input tokens."),
          bedrock_titan_embedding_response([1.0, 2.0, 3.0]),
        ],
      )

      long_text = "a" * described_class::INPUT_TEXT_LENGTH_LIMIT

      expect { described_class.call(long_text) }.to raise_error(
        described_class::InputTextTokenLimitExceededError,
        /Failed to generate Titan embedding after 5 attempts/,
      )

      expect(client.api_requests.size).to eq(5)
    end

    it "raises the original error if it is not a token limit error" do
      client = Aws::BedrockRuntime::Client.new(stub_responses: true)
      allow(Aws::BedrockRuntime::Client).to receive(:new).and_return(client)
      client.stub_responses(
        :invoke_model,
        [
          Aws::BedrockRuntime::Errors::ValidationException.new({}, "503 Service Unavailable"),
        ],
      )

      expect { described_class.call("text") }.to raise_error(
        Aws::BedrockRuntime::Errors::ValidationException,
      )
    end
  end
end
