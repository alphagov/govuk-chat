RSpec.describe "Search configuration" do
  describe "document_types_by_schema" do
    it "allows a content item from each schema to be converted into chunks" do
      schemas = Rails.configuration.search.document_types_by_schema

      schemas.each_key do |schema_name|
        content_item = build(:notification_content_item, schema_name)

        chunks = Chunking::ContentItemToChunks.call(content_item)
        expect(chunks).to be_an_instance_of(Array)
        expect(chunks).to all(be_a(Chunking::ContentItemChunk))
      end
    end

    it "requires all definitions to conform to a JSON schema" do
      schema = YAML.load_file(
        Rails.root.join("spec/fixtures/schemas/document_types_by_schema.yml"),
        aliases: true,
      )

      schemas = Rails.configuration.search.document_types_by_schema

      schemas.each_value do |schema_config|
        expect(JSON::Validator.validate!(schema, schema_config)).to be(true)
      end
    end

    it "requires all schema names to be valid Publishing API ones" do
      schemas = Rails.configuration.search.document_types_by_schema.keys
      all_valid_schema_names = GovukSchemas::Schema.schema_names

      unknown_schemas = schemas - all_valid_schema_names

      expect(unknown_schemas).to be_empty, "Schemas not in Publishing API: #{unknown_schemas.join(', ')}"
    end

    it "requires that all document types are valid for the schema" do
      schemas = Rails.configuration.search.document_types_by_schema

      schemas.each do |schema_name, schema_config|
        document_types = schema_config.fetch("document_types").keys

        govuk_schema = GovukSchemas::Schema.find(publisher_schema: schema_name)
        valid_document_types = govuk_schema.dig("properties", "document_type", "enum")

        unknown_document_types = document_types - valid_document_types
        message = "Document types not valid for #{schema_name}" \
          "schema: #{unknown_document_types.join(', ')}"
        expect(unknown_document_types).to be_empty, message
      end
    end

    it "requires that all required parent document types are valid" do
      schemas = Rails.configuration.search.document_types_by_schema

      schemas.each do |schema_name, schema_config|
        schema_config.fetch("document_types").each do |document_type, document_type_config|
          next unless document_type_config && document_type_config["requires_parent_document_type"]

          document_types = document_type_config["requires_parent_document_type"].keys

          unknown_document_types = document_types - GovukSchemas::DocumentTypes.valid_document_types
          message = "Parent document types not in the Publishing API " \
            "#{schema_name} schema, #{document_type} document type: " \
            "#{unknown_document_types.join(', ')}"

          expect(unknown_document_types).to be_empty, message
        end
      end
    end
  end
end
