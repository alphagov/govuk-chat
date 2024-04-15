RSpec.describe Search::TextToEmbedding do
  describe ".call" do
    it "returns a single embedding array for a string input" do
      to_embed = "text"
      stub_openai_embedding(to_embed)

      embedding = described_class.call(to_embed)

      expect(embedding)
        .to be_an_instance_of(Array)
        .and have_attributes(length: 1536)
    end

    it "returns an array of embedding arrays for an array input" do
      to_embed = ["Embed this", "Embed that"]
      stub_openai_embedding(to_embed)

      embedding_collection = described_class.call(to_embed)

      expect(embedding_collection)
        .to be_an_instance_of(Array)
        .and have_attributes(length: 2)
        .and all(have_attributes(length: 1536))
    end

    it "does multiple requests to OpenAI when the number of strings is greater than the batch size" do
      input_1 = Array.new(described_class::BATCH_SIZE, "to embed")
      input_2 = Array.new(5, "to embed in a second request")

      request_1 = stub_openai_embedding(input_1)
      request_2 = stub_openai_embedding(input_2)

      described_class.call(input_1 + input_2)

      expect(request_1).to have_been_made
      expect(request_2).to have_been_made
    end

    it "truncates input that exceeds the token limit to avoid a context length exceeded error" do
      very_long_input = "test " * 10_000

      encoder = Tiktoken.encoding_for_model(described_class::EMBEDDING_MODEL)

      request = stub_any_openai_embedding(embeddings_per_request: 1).with do |req|
        input = JSON.parse(req.body).dig("input", 0)
        input_tokens = encoder.encode(input)
        input.match(/test\s/) && input_tokens.length == described_class::INPUT_TOKEN_LIMIT
      end

      described_class.call(very_long_input)

      expect(request).to have_been_made
    end
  end
end
