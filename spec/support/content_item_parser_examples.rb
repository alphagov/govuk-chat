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
end
