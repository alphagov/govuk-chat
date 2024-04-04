module ContentItemParserExamples
  shared_examples "a chunking content item parser" do
    it "responds to .call with an array of Chunking::ContentItemChunk objects" do
      result = described_class.call(content_item)
      expect(result).to be_an_instance_of(Array)
      expect(result).to all(be_a(Chunking::ContentItemChunk))
    end
  end
end
