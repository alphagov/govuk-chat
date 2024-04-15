RSpec.describe Chunking::HtmlHierarchicalChunker::HtmlChunk do
  describe "#fragment" do
    it "returns the fragment of the last header" do
      instance = described_class.new(
        headers: [
          described_class::Header.new(element: "h2", text_content: "Heading", fragment: "heading"),
          described_class::Header.new(element: "h3", text_content: "Sub Heading", fragment: "sub-heading"),
        ],
        html_content: "<p>content</p>",
      )

      expect(instance.fragment).to eq("sub-heading")
    end

    it "returns the fragment of an earlier header if the last one doesn't have an id" do
      instance = described_class.new(
        headers: [
          described_class::Header.new(element: "h2", text_content: "Heading", fragment: "heading"),
          described_class::Header.new(element: "h3", text_content: "Sub Heading", fragment: nil),
        ],
        html_content: "<p>content</p>",
      )

      expect(instance.fragment).to eq("heading")
    end

    it "returns nil if no headers have a fragment" do
      instance = described_class.new(
        headers: [
          described_class::Header.new(element: "h2", text_content: "Heading", fragment: nil),
          described_class::Header.new(element: "h3", text_content: "Sub Heading", fragment: nil),
        ],
        html_content: "<p>content</p>",
      )

      expect(instance.fragment).to be_nil
    end

    it "returns nil if there are no headers" do
      instance = described_class.new(headers: [], html_content: "<p>content</p>")
      expect(instance.fragment).to be_nil
    end
  end
end
