RSpec.describe Chunking::HtmlHierarchicalChunker do
  describe ".call" do
    it "converts HTML into an array of HtmlChunk objects with HtmlChunk::Header objects for headers" do
      html = <<~HTML
        <p>Content</p>
        <h2>First heading</h2>
        <h3>Sub heading</h3>
        <p>More content</p>
        <p>Even more content</p>
        <h2>Second heading</h2>
        <p>More content still</p>
      HTML

      expect(described_class.call(html)).to eq([
        build_html_chunk([], "<p>Content</p>"),
        build_html_chunk(
          [build_header("h2", "First heading"), build_header("h3", "Sub heading")],
          "<p>More content</p>\n<p>Even more content</p>",
        ),
        build_html_chunk(
          [build_header("h2", "Second heading")],
          "<p>More content still</p>",
        ),
      ])
    end

    it "uses id values from headers to store a fragment that can be used for deep linking" do
      html = %(<h2 id="heading-2">Heading 2</h2><p>Content</p>)

      chunks = described_class.call(html)
      headers = chunks.first.headers
      expect(headers.first.fragment).to eq("heading-2")
    end

    it "delegates sanitising the HTML to HtmlSanitiser" do
      allow(Chunking::HtmlSanitiser).to receive(:call)
      html = "<h2>Heading</h2><p>Content</p>"
      described_class.call(html)
      expect(Chunking::HtmlSanitiser).to have_received(:call).with(html)
    end

    it "only groups headers that are semantically ordered" do
      html = <<~HTML
        <h2>The h2</h2>
        <h4>The h4</h4>
        <h3>The h3</h3>
        <h5>The h5</h5>
        <h6>The h6</h6>
        <p>Content</p>
      HTML

      expect(described_class.call(html)).to eq([
        build_html_chunk(
          [
            build_header("h2", "The h2"),
            build_header("h3", "The h3"),
            build_header("h5", "The h5"),
            build_header("h6", "The h6"),
          ],
          "<p>Content</p>",
        ),
      ])
    end
  end

  def build_html_chunk(headers, html_content)
    described_class::HtmlChunk.new(headers:, html_content:)
  end

  def build_header(element, text_content, fragment = nil)
    described_class::HtmlChunk::Header.new(element:, text_content:, fragment:)
  end
end
