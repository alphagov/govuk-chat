RSpec.describe Search::TextToEmbedding::Titan, :aws_credentials_stubbed do
  describe ".call" do
    it "returns a single embedding array for a string input" do
      request = stub_bedrock_titan_embedding("text")

      embedding = described_class.call("text")

      expect(request).to have_been_made.once
      expect(embedding).to eq(mock_titan_embedding("text"))
    end

    it "returns an array of embedding arrays for an array input" do
      first_request = stub_bedrock_titan_embedding("Embed this")
      second_request = stub_bedrock_titan_embedding("Embed that")

      embedding = described_class.call(["Embed this", "Embed that"])

      expect(first_request).to have_been_made.once
      expect(second_request).to have_been_made.once

      expect(embedding)
        .to eq([mock_titan_embedding("Embed this"), mock_titan_embedding("Embed that")])
    end

    it "truncates input text to the character length limit" do
      max_length_text = "a" * described_class::INPUT_TEXT_LENGTH_LIMIT
      longer_text = "#{max_length_text}a"
      request = stub_bedrock_titan_embedding(max_length_text)

      described_class.call(longer_text)

      expect(request).to have_been_made
    end

    it "retries embedding generation if the input exceeds the token limit" do
      first_error_request = stub_titan_too_many_tokens_error(
        "a" * described_class::INPUT_TEXT_LENGTH_LIMIT,
      )
      second_error_request = stub_titan_too_many_tokens_error("a" * 40_000)
      successful_request = stub_bedrock_titan_embedding("a" * 32_000)

      long_text = "a" * described_class::INPUT_TEXT_LENGTH_LIMIT
      described_class.call(long_text)

      expect(first_error_request).to have_been_made.once
      expect(second_error_request).to have_been_made.once
      expect(successful_request).to have_been_made.once
    end

    it "raises an error if embedding generation fails after max number of retries" do
      requests = [
        stub_titan_too_many_tokens_error(
          "a" * described_class::INPUT_TEXT_LENGTH_LIMIT,
        ),
        stub_titan_too_many_tokens_error("a" * 40_000),
        stub_titan_too_many_tokens_error("a" * 32_000),
        stub_titan_too_many_tokens_error("a" * 25_600),
        stub_titan_too_many_tokens_error("a" * 20_480),
      ]

      long_text = "a" * described_class::INPUT_TEXT_LENGTH_LIMIT

      expect { described_class.call(long_text) }.to raise_error(
        described_class::InputTextTokenLimitExceededError,
        /Failed to generate Titan embedding after 5 attempts/,
      )

      requests.all? { |request| expect(request).to have_been_made.once }
    end

    it "raises the original error if it is not a token limit error" do
      stub_bedrock_titan_invoke_error(
        "text",
        "400 Bad Request: Some other bad request error.",
      )

      expect { described_class.call("text") }.to raise_error(
        Aws::BedrockRuntime::Errors::ValidationException,
        "400 Bad Request: Some other bad request error.",
      )
    end
  end

  def stub_titan_too_many_tokens_error(input_text)
    stub_bedrock_titan_invoke_error(
      input_text,
      "400 Bad Request: Too many input tokens.",
    )
  end
end
