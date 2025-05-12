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

    it "truncates input text to the length limit" do
      client = stub_bedrock_invoke_model(
        bedrock_titan_embedding_response([1.0, 2.0, 3.0]),
      )

      long_text = "a" * (described_class::INPUT_TEXT_LENGTH_LIMIT + 1)
      described_class.call(long_text)

      expect(client.api_requests.size).to eq(1)

      request_body = JSON.parse(
        client.api_requests.first.dig(:params, :body),
      )

      expect(request_body["inputText"].length)
        .to eq(described_class::INPUT_TEXT_LENGTH_LIMIT)
    end
  end
end
