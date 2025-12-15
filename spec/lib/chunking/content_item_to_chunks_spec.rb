RSpec.describe Chunking::ContentItemToChunks do
  describe ".call" do
    it "returns an array of ContentItemChunk objects for a valid schema" do
      content_item = build(:notification_content_item, schema_name: "detailed_guide")
      response = described_class.call(content_item)

      expect(response).to all(be_a(Chunking::ContentItemChunk))
    end

    it "raises an error when given a schema that is not supported" do
      content_item = build(:notification_content_item).merge("schema_name" => "doesnt_exist")

      expect { described_class.call(content_item) }
        .to raise_error("Content item not supported for parsing: doesnt_exist is not a supported schema")
    end
  end

  describe ".non_indexable_content_item_reason" do
    context "when the schema can be handled by one of the parsers" do
      it "returns nil" do
        content_item = build(:notification_content_item, schema_name: "detailed_guide")
        expect(described_class.non_indexable_content_item_reason(content_item)).to be_nil
      end
    end

    context "when the schema is not handled by any of the parsers" do
      it "returns a message" do
        content_item = build(:notification_content_item, schema_name: "licence")
        expect(described_class.non_indexable_content_item_reason(content_item)).to eq(
          "licence is not a supported schema",
        )
      end
    end

    context "when the schema config defines a document_type" do
      it "returns nil when the document_type is supported" do
        content_item = build(:notification_content_item, schema_name: "detailed_guide")
        expect(described_class.non_indexable_content_item_reason(content_item)).to be_nil
      end

      it "returns the reason when the document_type is not supported" do
        content_item = build(:notification_content_item, schema_name: "publication", document_type: "correspondence")
        expect(described_class.non_indexable_content_item_reason(content_item)).to eq(
          "document type: correspondence not supported for schema: publication",
        )
      end
    end

    context "when the schema config defines a parent_document_type" do
      it "returns an error when the parent_document_type is missing" do
        content_item = build(:notification_content_item, schema_name: "html_publication", parent_document_type: nil)

        expect(described_class.non_indexable_content_item_reason(content_item)).to eq(
          "content item lacks a parent document_type",
        )
      end

      it "returns an error when the parent_document_type is not supported" do
        content_item = build(:notification_content_item, schema_name: "html_publication", parent_document_type: "decision")

        expect(described_class.non_indexable_content_item_reason(content_item)).to eq(
          "html_publication items with parent document type: decision are not supported",
        )
      end

      it "returns nil when the parent_document_type is supported" do
        content_item = build(:notification_content_item, schema_name: "html_publication", parent_document_type: "guidance")
        expect(described_class.non_indexable_content_item_reason(content_item)).to be_nil
      end
    end
  end
end
