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

    it "raises an error when given a document_type that is not supported" do
      content_item = build(:notification_content_item,
                           schema_name: "publication",
                           document_type: "decision")

      expect { described_class.call(content_item) }
        .to raise_error("Content item not supported for parsing: document type: decision not supported for schema: publication")
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

    context "when the schema/document_type is mapped to a parser but is not supported" do
      it "returns the reason from the parser" do
        content_item = build(:notification_content_item, schema_name: "publication", document_type: "correspondence")
        expect(described_class.non_indexable_content_item_reason(content_item)).to eq(
          "document type: correspondence not supported for schema: publication",
        )
      end
    end

    context "when mapped parser doesn't respond to :non_indexable_content_item_reason" do
      it "returns nil" do
        content_item = build(:notification_content_item, schema_name: "transaction")
        expect(described_class.non_indexable_content_item_reason(content_item)).to be_nil
      end
    end
  end
end
