RSpec.describe MessageQueue::ContentSynchroniser::IndexContentItem, :aws_credentials_stubbed, :chunked_content_index do
  describe ".call" do
    let(:base_path) { "/path" }
    let(:content_item) { build(:notification_content_item, base_path:) }
    let(:repository) { Search::ChunkedContentRepository.new }

    let(:chunks) do
      [
        build(:content_item_chunk, content_item:, chunk_index: 0),
        build(:content_item_chunk, content_item:, chunk_index: 1),
      ]
    end

    before do
      chunks.map(&:plain_content).each { |chunk| stub_bedrock_titan_embedding(chunk) }
      allow(Chunking::ContentItemToChunks).to receive(:call).with(content_item).and_return(chunks)
    end

    it "converts a content item into chunks and can insert them into the chunked content index" do
      expect { described_class.call(content_item, repository) }
        .to change { repository.count(term: { base_path: }) }
        .by(chunks.length)

      expect(Chunking::ContentItemToChunks).to have_received(:call).with(content_item)
    end

    it "applies Titan embedding to the data going into the search index" do
      allow(Search::TextToEmbedding::Titan).to receive(:call).and_call_original

      expect { described_class.call(content_item, repository) }
        .to change { repository.count(exists: { field: :titan_embedding }) }
        .by(chunks.length)

      expect(Search::TextToEmbedding::Titan).to have_received(:call)
    end

    it "returns a Result object" do
      expect(described_class.call(content_item, repository))
        .to be_an_instance_of(MessageQueue::ContentSynchroniser::Result)
        .and have_attributes(chunks_created: chunks.length,
                             chunks_updated: 0,
                             chunks_deleted: 0,
                             chunks_skipped: 0)
    end

    context "when the index already has items that match the digest" do
      it "skips updating them" do
        documents = chunks.each_with_object({}) do |c, memo|
          memo[c.id] = build(:chunked_content_record, base_path:, digest: c.digest)
        end
        populate_chunked_content_index(documents)

        result = nil

        expect { result = described_class.call(content_item, repository) }
          .not_to(change { repository.count(term: { base_path: }) })

        expect(result.chunks_skipped).to eq(chunks.length)
      end
    end

    context "when the index has existing items that don't match the digest" do
      it "updates them" do
        populate_chunked_content_index(chunks[0].id => build(:chunked_content_record, base_path:, digest: "111"))

        result = nil

        expect { result = described_class.call(content_item, repository) }
          .to change { repository.count(term: { digest: "111" }) }
          .by(-1)
          .and change { repository.count(term: { digest: chunks[0].digest }) }
          .by(1)

        expect(result.chunks_updated).to eq(1)
      end
    end

    context "when the index has extra items at the base path" do
      it "deletes them" do
        documents = chunks.each_with_object({}) do |c, memo|
          memo[c.id] = build(:chunked_content_record, base_path:, digest: c.digest)
        end
        populate_chunked_content_index(documents)

        # extra items
        populate_chunked_content_index([build(:chunked_content_record, base_path:, digest: "111"), build(:chunked_content_record, base_path:, digest: "222")])

        result = nil

        expect { result = described_class.call(content_item, repository) }
          .to change { repository.count(term: { base_path: }) }
          .by(-2)

        expect(result.chunks_deleted).to eq(2)
      end
    end

    context "when we get an unexpected result from the repository when indexing a document" do
      it "raises an error" do
        allow(repository).to receive(:index_document).and_return(:unexpected)

        expect { described_class.call(content_item, repository) }
          .to raise_error("Unexpected index document result: unexpected")
      end
    end
  end
end
