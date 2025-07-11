RSpec.describe GenerateTextEmbeddingJob, :chunked_content_index do
  describe "#perform" do
    it "logs an error if the document is not found" do
      expect(Rails.logger).to receive(:info).with("Document non_existent_id not found in the index.")
      described_class.new.perform("non_existent_id")
    end

    it "generates the embedding and indexes the document" do
      document = build(:chunked_content_record, plain_content: "Content", titan_embedding: nil)
      populate_chunked_content_index({ "id1" => document })
      stub_bedrock_titan_embedding("Content")

      expect(Rails.logger).to receive(:info).with("Successfully indexed document id1 with new embedding.")
      described_class.new.perform("id1")

      updated_document = chunked_content_search_client.get(index: chunked_content_index, id: "id1")
      expect(updated_document["_source"]["titan_embedding"]).to eq(mock_titan_embedding("Content"))
    end

    it "overwrites the existing embedding" do
      document = build(
        :chunked_content_record,
        plain_content: "Content",
        titan_embedding: mock_titan_embedding("Old Content"),
      )
      populate_chunked_content_index({ "id1" => document })
      stub_bedrock_titan_embedding("Content")

      described_class.new.perform("id1")

      updated_document = chunked_content_search_client.get(index: chunked_content_index, id: "id1")
      expect(updated_document["_source"]).to include({
        "titan_embedding" => mock_titan_embedding("Content"),
        "plain_content" => "Content",
      })
    end

    it "logs an error if the indexing fails" do
      repository = instance_double(Search::ChunkedContentRepository)
      allow(Search::ChunkedContentRepository).to receive(:new).and_return(repository)
      allow(repository).to receive(:chunk).with("id1").and_return(
        build(:chunked_content_search_result, plain_content: "Content"),
      )

      stub_bedrock_titan_embedding("Content")

      allow(repository).to receive(:update_document).and_return(:failed)

      expect(Rails.logger).to receive(:info).with("Failed to index document id1: unexpected result failed.")

      described_class.new.perform("id1")
    end
  end
end
