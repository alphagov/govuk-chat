module ContentItemParserExamples
  shared_examples "a chunking content item parser" do
    it "responds to .call with an array of Chunking::ContentItemChunk objects" do
      result = described_class.call(content_item)
      expect(result).to be_an_instance_of(Array)
      expect(result).to all(be_a(Chunking::ContentItemChunk))
    end

    it "responds to .allowed_schemas with a non-empty array" do
      result = described_class.allowed_schemas
      expect(result).to be_an_instance_of(Array)
      expect(result).not_to be_empty
    end
  end

  shared_examples "a parser that allows .allowed_schemas" do
    describe ".supported_schema_and_document_type?" do
      it "returns true for allowed_schemas" do
        described_class.allowed_schemas.each do |schema|
          expect(described_class.supported_schema_and_document_type?(schema, "anything")).to eq(true)
        end
      end

      it "returns false for unsupported schemas" do
        expect(described_class.supported_schema_and_document_type?("unknown", "anything")).to eq(false)
      end
    end
  end
end
