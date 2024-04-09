RSpec.describe MessageQueue::ContentSynchroniser, :chunked_content_index do
  let(:repository) { Search::ChunkedContentRepository.new }

  describe ".call" do
    let(:base_path) { "/path" }

    let(:content_item) do
      schema = GovukSchemas::Schema.find(notification_schema: "generic")
      GovukSchemas::RandomExample.new(schema:).payload.tap do |item|
        item["base_path"] = base_path
      end
    end

    let(:chunks) do
      [
        build(:content_item_chunk, content_item:, chunk_index: 0),
        build(:content_item_chunk, content_item:, chunk_index: 1),
      ]
    end

    before do
      stub_any_openai_embedding
      allow(Chunking::ContentItemToChunks).to receive(:call).with(content_item).and_return(chunks)
    end

    it "converts the content item into chunks and inserts these into the chunked content index" do
      expect { described_class.call(content_item) }
        .to change { repository.count(term: { base_path: }) }
        .by(chunks.length)
    end

    it "applies openai embedding to the data going into the search index" do
      expect { described_class.call(content_item) }
        .to change { repository.count(exists: { field: :openai_embedding }) }
        .by(chunks.length)
    end
  end
end
