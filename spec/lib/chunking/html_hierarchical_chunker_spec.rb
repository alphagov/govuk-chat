RSpec.describe Chunking::HtmlHierarchicalChunker do
  describe ".call" do
    let(:title) { "Main title here" }

    context "with divs at top level" do
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
        output = described_class.call(title:, html:)
        expect(output).to eq([
          {
            title: "Main title here",
            h2: "First subheading",
            html_content: "<p>First paragraph under subheading</p>\n<p>Second paragraph under subheading</p>",
          },
          {
            title: "Main title here",
            h2: "Second subheading",
            html_content: "<p>Another paragraph under the second subheading</p>",
          },
        ].map(&:stringify_keys))
      end
    end

    context "with divs below the top level" do
      let(:html) do
        <<~HTML
          <div class="govspeak">
            <h2>First subheading</h2>
            <p>First paragraph under subheading</p>
            <p>Second paragraph under subheading</p>
            <div>
              <h2>Second subheading</h2>
              <p>Another paragraph under the second subheading</p>
            </div>
            <h2>Third subheading</h2>
            <p>Paragraph under third subheading</p>
          </div>
        HTML
      end

      it "ignores the divs and produces the same format" do
        output = described_class.call(title:, html:)
        expect(output).to eq([
          {
            title: "Main title here",
            h2: "First subheading",
            html_content: "<p>First paragraph under subheading</p>\n<p>Second paragraph under subheading</p>",
          },
          {
            title: "Main title here",
            h2: "Second subheading",
            html_content: "<p>Another paragraph under the second subheading</p>",
          },
          {
            title: "Main title here",
            h2: "Third subheading",
            html_content: "<p>Paragraph under third subheading</p>",
          },
        ].map(&:stringify_keys))
      end
    end

    context "without divs at top level including h1 tags" do
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
        output = described_class.call(title:, html:)
        expect(output).to eq([
          {
            title: "Main title here",
            h2: "First subheading",
            html_content: "<p>First paragraph under subheading</p>\n<p>Second paragraph under subheading</p>",
          },
          {
            title: "Main title here",
            h2: "Second subheading",
            html_content: "<p>Another paragraph under the second subheading</p>",
          },
        ].map(&:stringify_keys))
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
        output = described_class.call(title:, html:)
        expect(output).to eq([
          {
            title: "Main title here",
            h2: "First subheading",
            h3: "first h3",
            h4: "first h4",
            h5: "first h5",
            h6: "first h6",
            html_content: "<p>First paragraph under h6</p>\n<p>Second paragraph under h6</p>",
          },
          {
            title: "Main title here",
            h2: "First subheading",
            h3: "first h3",
            h4: "first h4",
            h5: "first h5",
            h6: "Second h6",
            html_content: "<p>Another paragraph under the second h6</p>",
          },
          {
            title: "Main title here",
            h2: "Second subheading",
            html_content: "<p>Another paragraph under the second subheading</p>",
          },
        ].map(&:stringify_keys))
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
        output = described_class.call(title:, html:)
        expect(output).to eq([
          {
            title: "Main title here",
            h2: "First subheading",
            html_content: "<p>First paragraph under subheading</p>\n<p>Second paragraph under subheading</p>",
          },
        ].map(&:stringify_keys))
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
        output = described_class.call(title:, html:)
        expect(output).to eq([
          {
            title: "Main title here",
            h2: "First subheading",
            html_content: "<p>First paragraph under subheading <a href=\"https://example.com/path\">Link text</a></p>\n<p>Second paragraph under subheading</p>",
          },
          {
            title: "Main title here",
            h2: "Second subheading",
            html_content: "<p>paragraph under second subheading</p>\n<abbr title=\"some title\">some content</abbr>",
          },
        ].map(&:stringify_keys))
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
        output = described_class.call(title:, html:)
        expect(output).to eq([
          {
            title: "Main title here",
            h2: "First subheading",
            html_content: "<p>First paragraph under subheading</p>\n<p>Second paragraph under subheading</p>",
          },
          {
            title: "Main title here",
            h2: "Heading after footnotes",
            html_content: "<p>Some text after footnotes</p>",
          },
        ].map(&:stringify_keys))
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
        output = described_class.call(title:, html:)
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
          {
            title: "Main title here",
            h2: "First subheading",
            html_content: expected_html.chomp,
          },
          {
            title: "Main title here",
            h2: "Second subheading",
            html_content: expected_ul_html.chomp,
          },
        ].map(&:stringify_keys))
      end
    end
  end
end
