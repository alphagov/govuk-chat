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

    it "does multiple requests to OpenAI when combined text length exceeds the OpenAI limit" do
      input_1 = "A short message"
      input_2 = "Another short message"
      input_3 = "A super long message that is very repetitive " * 8000

      request_1 = stub_openai_embedding([input_1, input_2])
      request_2 = stub_openai_embedding([input_3])

      described_class.call([input_1, input_2, input_3])

      expect(request_1).to have_been_made
      expect(request_2).to have_been_made
    end
  end
end
