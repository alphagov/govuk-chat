RSpec.describe "Search configuration" do
  describe "document_types_by_schema" do
    it "requires all schemas to contain only BaseParser descendants" do
      schemas = Rails.configuration.search.document_types_by_schema

      parser_classes = schemas.each_value.map do |schema_config|
        parser = schema_config.fetch("parser")

        "Chunking::ContentItemParsing::#{parser.classify}".constantize
      end

      expect(parser_classes.uniq).to match_array(Chunking::ContentItemParsing::BaseParser.descendants)
    end

    it "requires all schemas to have a list of document types" do
      schemas = Rails.configuration.search.document_types_by_schema

      schemas.each_value do |schema_config|
        document_types = schema_config.fetch("document_types")
        expect(document_types).to be_a(Hash)
      end
    end

    it "requires all schema names to be valid Publishing API ones" do
      schemas = Rails.configuration.search.document_types_by_schema.keys
      all_valid_schema_names = GovukSchemas::Schema.schema_names

      unknown_schemas = schemas - all_valid_schema_names

      expect(unknown_schemas).to be_empty, "Schemas not in Publishing API: #{unknown_schemas.join(', ')}"
    end

    it "requires that all schemas have valid document types" do
      schemas = Rails.configuration.search.document_types_by_schema

      schemas.each do |schema_name, schema_config|
        # HTML publication is a special case, as the document type check happens
        # on its parent document type. The parser handles this logic.
        next if schema_name == "html_publication"

        document_types = schema_config.fetch("document_types").keys

        govuk_schema = GovukSchemas::Schema.find(publisher_schema: schema_name)
        valid_document_types = govuk_schema.dig("properties", "document_type", "enum")

        unknown_document_types = document_types - valid_document_types
        expect(unknown_document_types).to be_empty, "Document types not in the Publishing API #{schema_name} schema: #{unknown_document_types.join(', ')}"
      end
    end
  end
end
