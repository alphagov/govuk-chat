module ContentItemParserExamples
  shared_examples "a chunking content item parser" do
    parser_class = described_class.name
    schemas = Rails.configuration.search.document_types_by_schema.select do |_, config|
      config.parser == parser_class
    end

    schemas.each do |schema_name|
      context "when the content items uses the '#{schema_name}' schema" do
        let(:schema_name) { schema_name }

        it "responds to .call with an array of Chunking::ContentItemChunk objects" do
          result = described_class.call(content_item)
          expect(result).to be_an_instance_of(Array)
          expect(result).to all(be_a(Chunking::ContentItemChunk))
          expect(result).not_to be_empty
        end
      end
    end
  end
end
