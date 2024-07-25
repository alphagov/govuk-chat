RSpec.describe Chunking::HtmlHierarchicalChunker do
  describe ".call" do
    it "returns an array of HtmlChunk objects" do
      html = "<p>Content</p><h2>Heading</h2><p>More content</p>"
      expect(described_class.call(html))
        .to be_an_instance_of(Array)
        .and all(be_a(described_class::HtmlChunk))
    end

    it "includes an array of HtmlChunk::Header objects within the HtmlChunks" do
      html = "<h2>Heading</h2><h3>Sub Heading</h3><p>Content</p>"
      chunk = described_class.call(html).first
      expect(chunk.headers)
        .to be_an_instance_of(Array)
        .and all(be_a(described_class::HtmlChunk::Header))
    end

    it "uses id values from headers to store a fragment that can be used for deep linking" do
      html = %(<h2 id="heading-2">Heading 2</h2><p>Content</p>)

      chunks = described_class.call(html)
      headers = chunks.first.headers
      expect(headers.first.fragment).to eq("heading-2")
    end

    context "with content within a container element" do
      let(:html) do
        <<~HTML
          <div class="govspeak">
            <h2>First subheading</h2>
            <p>First paragraph under subheading</p>
            <p>Second paragraph under subheading</p>
            <h2>Second subheading</h2>
            <p>Another paragraph under the second subheading</p>
          </div>
        HTML
      end

      it "splits HTML into parts based using the title as h1" do
        output = described_class.call(html)
        expect(output).to eq([
          build_html_chunk(
            [build_header("h2", "First subheading")],
            "<p>First paragraph under subheading</p>\n<p>Second paragraph under subheading</p>",
          ),
          build_html_chunk(
            [build_header("h2", "Second subheading")],
            "<p>Another paragraph under the second subheading</p>",
          ),
        ])
      end
    end

    context "with html within a variety of container elements" do
      let(:html) do
        <<~HTML
          <main>
            <div>
              <header>
                <h2>First subheading</h2>
                <p>First paragraph under subheading</p>
              </header>
              <nav>
                <article>
                  <p>Second paragraph under subheading</p>
                </article>
              </nav>
              <section>
                <h2>Second subheading</h2>
                <p>Another paragraph under the second subheading</p>
              </section>
              <footer>
                <details>
                  <summary>
                    <h2>Third subheading</h2>
                  </summary>
                  <div>
                    <p>Paragraph under third subheading</p>
                  </div>
                </details>
              </footer>
            </div>
          </main>
        HTML
      end

      it "ignores the container element and produces the same format" do
        output = described_class.call(html)
        expect(output).to eq([
          build_html_chunk(
            [build_header("h2", "First subheading")],
            "<p>First paragraph under subheading</p>\n<p>Second paragraph under subheading</p>",
          ),
          build_html_chunk(
            [build_header("h2", "Second subheading")],
            "<p>Another paragraph under the second subheading</p>",
          ),
          build_html_chunk(
            [build_header("h2", "Third subheading")],
            "<p>Paragraph under third subheading</p>",
          ),
        ])
      end
    end

    context "without container elements at top level including h1 tags" do
      let(:html) do
        <<~HTML
          <h1>A different main title here</h1>
          <h2>First subheading</h2>
          <p>First paragraph under subheading</p>
          <p>Second paragraph under subheading</p>
          <h2>Second subheading</h2>
          <p>Another paragraph under the second subheading</p>
        HTML
      end

      it "splits HTML into parts ignoring existing h1 tags" do
        output = described_class.call(html)
        expect(output).to eq([
          build_html_chunk(
            [build_header("h2", "First subheading")],
            "<p>First paragraph under subheading</p>\n<p>Second paragraph under subheading</p>",
          ),
          build_html_chunk(
            [build_header("h2", "Second subheading")],
            "<p>Another paragraph under the second subheading</p>",
          ),
        ])
      end
    end

    context "with content before a heading" do
      let(:html) do
        <<~HTML
          <p>Some content</p>
          <h2>Heading 2</h2>
          <p>More content</p>
        HTML
      end

      it "splits HTML into parts with the first one missing a header" do
        output = described_class.call(html)
        expect(output).to eq([
          build_html_chunk([], "<p>Some content</p>"),
          build_html_chunk(
            [build_header("h2", "Heading 2")],
            "<p>More content</p>",
          ),
        ])
      end
    end

    context "with content inbetween headings" do
      let(:html) do
        <<~HTML
          <h2>Heading 2</h2>
          <p>Some content</p>
          <h3>Heading 3</h3>
          <p>More content</p>
        HTML
      end

      it "splits the content into chunks that include their content" do
        output = described_class.call(html)
        expect(output).to eq([
          build_html_chunk(
            [build_header("h2", "Heading 2")],
            "<p>Some content</p>",
          ),
          build_html_chunk(
            [build_header("h2", "Heading 2"), build_header("h3", "Heading 3")],
            "<p>More content</p>",
          ),
        ])
      end
    end

    context "with headings out of order" do
      let(:html) do
        <<~HTML
          <h5>Heading 5</h5>
          <p>H5 content</p>
          <h4>Heading 4</h4>
          <h3>Heading 3</h3>
          <p>H3 content</p>
          <h2>Heading 2</h2>
          <h4>Heading 4</h4>
          <p>H2 H4 content</p>
        HTML
      end

      it "only pays attention to headers that are of a lower precedence" do
        output = described_class.call(html)
        expect(output).to eq([
          build_html_chunk(
            [build_header("h5", "Heading 5")],
            "<p>H5 content</p>",
          ),
          build_html_chunk(
            [build_header("h3", "Heading 3")],
            "<p>H3 content</p>",
          ),
          build_html_chunk(
            [build_header("h2", "Heading 2"), build_header("h4", "Heading 4")],
            "<p>H2 H4 content</p>",
          ),
        ])
      end
    end

    context "with content at h6 level" do
      let(:html) do
        <<~HTML
          <h2>First subheading</h2>
          <h3>first h3</h3>
          <h4>first h4</h4>
          <h5>first h5</h5>
          <h6>first h6</h6>
          <p>First paragraph under h6</p>
          <p>Second paragraph under h6</p>
          <h6>Second h6</h6>
          <p>Another paragraph under the second h6</p>
          <h2>Second subheading</h2>
          <p>Another paragraph under the second subheading</p>
        HTML
      end

      it "splits HTML into parts ignoring existing h1 tags" do
        output = described_class.call(html)
        expect(output).to eq([
          build_html_chunk(
            [
              build_header("h2", "First subheading"),
              build_header("h3", "first h3"),
              build_header("h4", "first h4"),
              build_header("h5", "first h5"),
              build_header("h6", "first h6"),
            ],
            "<p>First paragraph under h6</p>\n<p>Second paragraph under h6</p>",
          ),
          build_html_chunk(
            [
              build_header("h2", "First subheading"),
              build_header("h3", "first h3"),
              build_header("h4", "first h4"),
              build_header("h5", "first h5"),
              build_header("h6", "Second h6"),
            ],
            "<p>Another paragraph under the second h6</p>",
          ),
          build_html_chunk(
            [build_header("h2", "Second subheading")],
            "<p>Another paragraph under the second subheading</p>",
          ),
        ])
      end
    end

    context "with unnecessary newlines" do
      let(:html) do
        <<~HTML
          <h1>A different Main title here</h1>

          <h2>First subheading</h2>


          <p>First paragraph under subheading</p>

          <p>Second paragraph under subheading</p>
        HTML
      end

      it "formats elements separated by single newline" do
        output = described_class.call(html)
        expect(output).to eq([
          build_html_chunk(
            [build_header("h2", "First subheading")],
            "<p>First paragraph under subheading</p>\n<p>Second paragraph under subheading</p>",
          ),
        ])
      end
    end

    context "with unnecessary attributes" do
      let(:html) do
        <<~HTML
          <h2>First subheading</h2>
          <p class="some class">First paragraph under subheading <a href="https://example.com/path" id="some-id">Link text</a></p>
          <p id="another-id">Second paragraph under subheading</p>
          <h2>Second subheading</h2>
          <p class="something">paragraph under second subheading</p>
          <abbr title="some title" id="abbr">some content</abbr>
        HTML
      end

      it "strips out attributes except href from <a> and title from <abbr>" do
        output = described_class.call(html)
        expect(output).to eq([
          build_html_chunk(
            [build_header("h2", "First subheading")],
            "<p>First paragraph under subheading <a href=\"https://example.com/path\">Link text</a></p>\n<p>Second paragraph under subheading</p>",
          ),
          build_html_chunk(
            [build_header("h2", "Second subheading")],
            "<p>paragraph under second subheading</p>\n<abbr title=\"some title\">some content</abbr>",
          ),
        ])
      end
    end

    context "with footnotes" do
      let(:html) do
        <<~HTML
          <h2>First subheading</h2>
          <p>First paragraph under subheading</p>
          <p>Second paragraph under subheading</p>
          <div class="footnotes"><p>Some footnotes here</p></div>
          <h2>Heading after footnotes</h2>
          <p>Some text after footnotes</p>
        HTML
      end

      it "removes the footnotes" do
        output = described_class.call(html)
        expect(output).to eq([
          build_html_chunk(
            [build_header("h2", "First subheading")],
            "<p>First paragraph under subheading</p>\n<p>Second paragraph under subheading</p>",
          ),
          build_html_chunk(
            [build_header("h2", "Heading after footnotes")],
            "<p>Some text after footnotes</p>",
          ),
        ])
      end
    end

    context "with tables and lists" do
      let(:html) do
        <<~HTML
          <h2>First subheading</h2>
          <p>First paragraph under subheading</p>
          <table>
             <thead>
                <tr class="something">
                  <th class="header">Header 1</th>
                  <th class="header">Header 2</th>
                </tr>
             </thead>
             <tbody>
              <tr id="id-1">
                  <td>Column 1 data</td>
                  <td>Column 2 data</td>
              </tr>
             </tbody>
           </table>
           <h2>Second subheading</h2>
          <p>Paragraph under second subheading</p>
          <ul class="something" id="some-id">
            <li class="selected" id="some-id">first item</li>
            <li>second item</li>
          </ul>
          <ol class="something" id="some-id">
            <li class="selected" id="some-id">first item</li>
            <li>second item</li>
          </ol>
        HTML
      end

      it "renders the table correctly" do
        output = described_class.call(html)
        expected_html = <<~HTML
          <p>First paragraph under subheading</p>
          <table>
             <thead>
                <tr>
                  <th>Header 1</th>
                  <th>Header 2</th>
                </tr>
             </thead>
             <tbody>
              <tr>
                  <td>Column 1 data</td>
                  <td>Column 2 data</td>
              </tr>
             </tbody>
           </table>
        HTML

        expected_ul_html = <<~HTML
          <p>Paragraph under second subheading</p>
          <ul>
            <li>first item</li>
            <li>second item</li>
          </ul>
          <ol>
            <li>first item</li>
            <li>second item</li>
          </ol>
        HTML
        expect(output).to eq([
          build_html_chunk(
            [build_header("h2", "First subheading")],
            expected_html.chomp,
          ),
          build_html_chunk(
            [build_header("h2", "Second subheading")],
            expected_ul_html.chomp,
          ),
        ])
      end
    end
  end

  def build_html_chunk(headers, html_content)
    described_class::HtmlChunk.new(headers:, html_content:)
  end

  def build_header(element, text_content, fragment = nil)
    described_class::HtmlChunk::Header.new(element:, text_content:, fragment:)
  end
end
