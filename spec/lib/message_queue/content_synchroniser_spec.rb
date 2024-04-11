RSpec.describe MessageQueue::ContentSynchroniser, :chunked_content_index do
  let(:repository) { Search::ChunkedContentRepository.new }

  shared_examples "deletes with a skip index reason" do |skip_index_reason|
    it "returns a Result object" do
      expect(described_class.call(content_item))
        .to be_an_instance_of(described_class::Result)
        .and have_attributes(chunks_deleted: 0, skip_index_reason:)
    end

    it "deletes any content that is indexed at the content's base_path" do
      populate_chunked_content_index([{ base_path: }])

      result = nil
      expect { result = described_class.call(content_item) }
        .to change { repository.count(term: { base_path: }) }
        .by(-1)

      expect(result.chunks_deleted).to eq(1)
    end
  end

  describe ".call" do
    let(:base_path) { "/path" }

    context "when content can be indexed" do
      let(:content_item) { build(:notification_content_item, base_path:, schema_name: "news_article") }

      it "delegates to IndexContentItem" do
        allow(described_class::IndexContentItem).to receive(:call)

        described_class.call(content_item)

        expect(described_class::IndexContentItem)
          .to have_received(:call)
          .with(content_item, an_instance_of(Search::ChunkedContentRepository))
      end
    end

    context "when content is in a non-English locale" do
      include_examples "deletes with a skip index reason", "has a non-English locale" do
        let(:content_item) do
          build(:notification_content_item, base_path:, schema_name: "news_article", locale: "cy")
        end
      end
    end

    context "when content uses a schema that isn't supported" do
      include_examples "deletes with a skip index reason", %(uses schema "gone") do
        let(:content_item) { build(:notification_content_item, schema_name: "gone", base_path:) }
      end
    end

    context "when content is withdrawn" do
      include_examples "deletes with a skip index reason", "is withdrawn" do
        let(:content_item) do
          build(:notification_content_item, schema_name: "news_article", base_path:, withdrawn: true)
        end
      end
    end
  end
end
