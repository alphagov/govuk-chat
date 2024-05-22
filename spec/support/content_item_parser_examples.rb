module ContentItemParserExamples
  shared_examples "a chunking content item parser" do |schemas|
    schemas.each do |schema|
      schema_name = schema.is_a?(Hash) ? schema.keys.first : schema
      document_type = schema.is_a?(Hash) ? schema.values.first : :preserve

      context "when the content items uses the '#{schema_name}' schema" do
        let(:schema_name) { schema_name }
        let(:document_type) { document_type }

        it "responds to .call with an array of Chunking::ContentItemChunk objects" do
          result = described_class.call(content_item)
          expect(result).to be_an_instance_of(Array)
          expect(result).to all(be_a(Chunking::ContentItemChunk))
          expect(result).not_to be_empty
        end
      end
    end

    it "responds to .allowed_schemas with an array of valid schemas" do
      result = described_class.allowed_schemas
      expect(result).to be_an_instance_of(Array)
      unexpected_schemas = result - GovukSchemas::Schema.schema_names
      expect(unexpected_schemas).to be_empty, "schema(s) #{unexpected_schemas.join(', ')} are not known to GovukSchemas"
    end
  end
end
