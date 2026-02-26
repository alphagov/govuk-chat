RSpec.describe Search::TextToEmbedding::TitanAsync, :aws_credentials_stubbed do
  around do |example|
    ClimateControl.modify(
      AWS_ACCESS_KEY_ID: "fake_access_key",
      AWS_SECRET_ACCESS_KEY: "fake_secret_key",
      AWS_SESSION_TOKEN: "fake_session_token",
      AWS_REGION: "eu-west-1",
      AWS_DEFAULT_REGION: "eu-west-1",
    ) do
      example.run
    end
  end

  describe ".call" do
    it "returns a single embedding array for a string input" do
      request = stub_titan_async_embedding("text")

      embedding = described_class.call("text")

      expect(request).to have_been_made.once
      expect(embedding).to eq(mock_titan_embedding("text"))
    end

    it "returns an array of embedding arrays for an array input" do
      first_request = stub_titan_async_embedding("Embed this")
      second_request = stub_titan_async_embedding("Embed that")

      embedding = described_class.call(["Embed this", "Embed that"])

      expect(first_request).to have_been_made.once
      expect(second_request).to have_been_made.once
      expect(embedding)
        .to eq([mock_titan_embedding("Embed this"), mock_titan_embedding("Embed that")])
    end
  end

  def stub_titan_async_embedding(text)
    stub_request(:post, StubBedrock::TITAN_EMBEDDING_ENDPOINT_REGEX)
      .with(body: { inputText: text }.to_json)
      .to_return_json(
        status: 200,
        body: bedrock_titan_embedding_response(mock_titan_embedding(text)),
        headers: { "Content-Type" => "application/json" },
      )
  end
end
