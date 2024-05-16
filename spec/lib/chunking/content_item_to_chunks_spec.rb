RSpec.describe Chunking::ContentItemToChunks do
  describe "PARSERS_FOR_SCHEMAS" do
    it "contains all BaseParser descendants" do
      expect(described_class::PARSERS_FOR_SCHEMAS).to match_array(Chunking::ContentItemParsing::BaseParser.descendants)
    end
  end

  describe ".call" do
    it "returns an array of ContentItemChunk objects for a valid schema" do
      content_item = build(:notification_content_item, schema_name: "news_article")
      response = described_class.call(content_item)

      expect(response).to all(be_a(Chunking::ContentItemChunk))
    end

    it "raises an error when given a schema that is not supported" do
      content_item = build(:notification_content_item, ensure_valid: false).merge(
        "schema_name" => "doesnt_exist",
        "document_type" => "any",
      )

      expect { described_class.call(content_item) }
        .to raise_error("Content item not supported for parsing: doesnt_exist is not a supported schema")
    end

    it "raises an error when given a document_type that is not supported" do
      content_item = build(:notification_content_item, ensure_valid: false).merge(
        "schema_name" => "publication",
        "document_type" => "decision",
      )

      expect { described_class.call(content_item) }
        .to raise_error("Content item not supported for parsing: document type: decision not supported for schema: publication")
    end
  end

  describe ".parsers_by_schema_name" do
    it "returns a hash of schema names that are all valid Publishing API ones" do
      schemas = described_class.parsers_by_schema_name.keys
      all_valid_schema_names = GovukSchemas::Schema.schema_names

      unknown_schemas = schemas - all_valid_schema_names

      expect(unknown_schemas).to be_empty, "Schemas not in Publishing API: #{unknown_schemas.join(', ')}"
    end

    it "maps schemas defined in all parser classes" do
      map = described_class.parsers_by_schema_name
      expect(map.values.uniq).to match_array(described_class::PARSERS_FOR_SCHEMAS)
    end
  end

  describe ".supported_schema_and_document_type?" do
    it "delegates to the method on the mapped parser" do
      allow(Chunking::ContentItemParsing::BodyContentParser)
        .to receive(:supported_schema_and_document_type?)
        .and_return(true)
      expect(described_class.supported_schema_and_document_type?("consultation", "anything")).to eq(true)
      expect(Chunking::ContentItemParsing::BodyContentParser)
        .to have_received(:supported_schema_and_document_type?).with("consultation", "anything")
    end

    it "returns false for unsupported schemas" do
      expect(described_class.supported_schema_and_document_type?("unknown", "anything")).to eq(false)
    end
  end

  describe ".non_indexable_content_item_reason" do
    context "when the schema can be handled by one of the parsers" do
      it "returns nil" do
        content_item = build(:notification_content_item, schema_name: "case_study")
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
