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

  describe ".supported_schemas" do
    it "returns a list of schema names that are all valid Publishing API ones" do
      schemas = described_class.supported_schemas
      all_valid_schema_names = GovukSchemas::Schema.schema_names

      unknown_schemas = schemas - all_valid_schema_names

      expect(unknown_schemas).to be_empty, "Schemas not in Publishing API: #{unknown_schemas.join(', ')}"
    end
  end

  describe ".supported_schema_and_document_type??" do
    it "returns true for schemas that don't care about document type" do
      %w[answer
         call_for_evidence
         consultation
         detailed_guide
         help_page
         hmrc_manual_section
         history
         manual
         manual_section
         news_article
         guide
         service_manual_guide
         transaction].each do |schema|
        expect(described_class.supported_schema_and_document_type?(schema, "anything")).to eq(true)
      end
    end

    it "returns false for unsupported schemas" do
      expect(described_class.supported_schema_and_document_type?("unknown", "anything")).to eq(false)
    end

    %w[correspondence decision].each do |document_type|
      it "rejects '#{document_type}' document type for 'publication' schema" do
        expect(described_class.supported_schema_and_document_type?("publication", document_type)).to eq(false)
      end
    end

    it "allows other document types for 'publication' schema" do
      %w[anything anything_else].each do |document_type|
        expect(described_class.supported_schema_and_document_type?("publication", document_type)).to eq(true)
      end
    end
  end
end
