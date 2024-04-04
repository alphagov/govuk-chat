RSpec.describe Chunking::ContentItemToChunks do
  describe ".call" do
    it "returns an array of ContentItemChunk objects for a valid schema" do
      schema = GovukSchemas::Schema.find(notification_schema: "news_article")
      content_item = GovukSchemas::RandomExample.new(schema:).payload
      response = described_class.call(content_item)

      expect(response).to all(be_a(Chunking::ContentItemChunk))
    end

    it "raises an error when given a schema that is not supported" do
      schema = GovukSchemas::Schema.find(notification_schema: "generic")
      content_item = GovukSchemas::RandomExample.new(schema:).payload
      content_item["schema_name"] = "doesnt_exist"

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
end
