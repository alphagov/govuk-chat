RSpec.describe Chunking::ContentItemToChunks do
  describe ".call" do
    it "returns an array of ContentItemChunk objects for a valid schema" do
      content_item = build(:notification_content_item, schema_name: "news_article")
      response = described_class.call(content_item)

      expect(response).to all(be_a(Chunking::ContentItemChunk))
    end

    it "raises an error when given a schema that is not supported" do
      content_item = build(:notification_content_item).merge("schema_name" => "doesnt_exist")

      expect { described_class.call(content_item) }
        .to raise_error("No content item parser configured for doesnt_exist")
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
      expect(map).to include(
        "answer" => Chunking::ContentItemParsing::BodyContentParser,
        "guide" => Chunking::ContentItemParsing::GuideParser,
        "transaction" => Chunking::ContentItemParsing::TransactionParser,
      )
    end
  end

  describe ".supported_schema_and_document_type?" do
    it "returns true for schemas that can be handled by a parser" do
      %w[answer guide transaction].each do |schema|
        expect(described_class.supported_schema_and_document_type?(schema, "anything")).to eq(true)
      end
    end

    it "returns false for unsupported schemas" do
      expect(described_class.supported_schema_and_document_type?("unknown", "anything")).to eq(false)
    end
  end
end
