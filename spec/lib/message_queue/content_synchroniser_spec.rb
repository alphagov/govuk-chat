RSpec.describe MessageQueue::ContentSynchroniser, :chunked_content_index do
  let(:repository) { Search::ChunkedContentRepository.new }

  describe ".call" do
    let(:content_item) do
      schema = GovukSchemas::Schema.find(notification_schema: "generic")
      GovukSchemas::RandomExample.new(schema:).payload
    end

    it "converts the content item into chunks and inserts these into the chunked content index" do
      content_item["base_path"] = "/path"
      chunk_1 = build(:content_item_chunk, content_item:, chunk_index: 0)
      chunk_2 = build(:content_item_chunk, content_item:, chunk_index: 1)

      allow(Chunking::ContentItemToChunks).to receive(:call).with(content_item).and_return([chunk_1, chunk_2])

      expect { described_class.call(content_item) }
        .to change { repository.count(term: { base_path: "/path" }) }
        .by(2)
    end
  end
end
