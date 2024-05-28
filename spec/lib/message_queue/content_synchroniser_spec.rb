RSpec.describe MessageQueue::ContentSynchroniser, :chunked_content_index do
  let(:repository) { Search::ChunkedContentRepository.new }

  shared_examples "deletes with a skip index reason" do |skip_index_reason|
    it "returns a Result object" do
      expect(described_class.call(content_item))
        .to be_an_instance_of(described_class::Result)
        .and have_attributes(chunks_deleted: 0, skip_index_reason:)
    end

    it "deletes any content that is indexed at the content's base_path" do
      populate_chunked_content_index([build(:chunked_content_record, base_path:)])

      result = nil
      expect { result = described_class.call(content_item) }
        .to change { repository.count(term: { base_path: }) }
        .by(-1)

      expect(result.chunks_deleted).to eq(1)
    end
  end

  shared_examples "allows content indexing" do
    it "delegates to IndexContentItem" do
      allow(described_class::IndexContentItem).to receive(:call)

      described_class.call(content_item)

      expect(described_class::IndexContentItem)
        .to have_received(:call)
        .with(content_item, an_instance_of(Search::ChunkedContentRepository))
    end
  end

  describe ".call" do
    let(:base_path) { "/path" }

    context "when content can be indexed" do
      include_examples "allows content indexing" do
        let(:content_item) do
          build(:notification_content_item,
                base_path:,
                schema_name: "detailed_guide",
                current_government: true)
        end
      end
    end

    context "when content is in a non-English locale" do
      include_examples "deletes with a skip index reason", "has a non-English locale" do
        let(:content_item) do
          build(:notification_content_item, base_path:, schema_name: "detailed_guide", locale: "cy")
        end
      end
    end

    context "when content uses a schema that isn't supported" do
      include_examples "deletes with a skip index reason", "gone is not a supported schema" do
        let(:content_item) { build(:notification_content_item, schema_name: "gone", base_path:) }
      end
    end

    context "when content is withdrawn" do
      include_examples "deletes with a skip index reason", "is withdrawn" do
        let(:content_item) do
          build(:notification_content_item, schema_name: "detailed_guide", base_path:, withdrawn: true)
        end
      end
    end

    context "when the content is in history mode" do
      include_examples "deletes with a skip index reason", "is in history mode" do
        let(:content_item) do
          build(:notification_content_item,
                schema_name: "detailed_guide",
                base_path:,
                details_merge: { "political" => true },
                current_government: false)
        end
      end
    end

    context "when the content is political but government is current" do
      include_examples "allows content indexing" do
        let(:content_item) do
          build(:notification_content_item,
                schema_name: "detailed_guide",
                base_path:,
                details_merge: { "political" => true },
                current_government: true)
        end
      end
    end

    context "when the content is not political and government is not current" do
      include_examples "allows content indexing" do
        let(:content_item) do
          build(:notification_content_item,
                schema_name: "detailed_guide",
                base_path:,
                details_merge: { "political" => false },
                current_government: false)
        end
      end
    end

    context "when the content is political and government is missing" do
      include_examples "allows content indexing" do
        let(:content_item) do
          build(:notification_content_item,
                schema_name: "detailed_guide",
                base_path:,
                current_government: nil,
                details_merge: { "political" => true })
        end
      end
    end
  end
end
