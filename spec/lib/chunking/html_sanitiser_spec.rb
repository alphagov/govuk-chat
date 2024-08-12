RSpec.describe Chunking::HtmlSanitiser do
  describe ".call" do
    it "returns a HTML string" do
      html = "<p>content</p>"
      expect(described_class.call(html)).to eq(html)
    end

    it "strips any footnotes" do
      html = <<~HTML
        <h2>First subheading</h2>
        <div class="footnotes"><p>Some footnotes here</p></div>
        <h2>Heading after footnotes</h2>
      HTML

      expect(described_class.call(html))
        .to eq("<h2>First subheading</h2>\n\n<h2>Heading after footnotes</h2>\n")
    end

    describe "stripping attributes" do
      %w[h2 h3 h4 h5 h6].each do |element|
        it "strips out everything but id for a <#{element}>" do
          html = %(<#{element} class="something" id="some-id">Heading</#{element}>)
          expect(described_class.call(html))
            .to eq(%(<#{element} id="some-id">Heading</#{element}>))
        end
      end

      it "strips out everything but href for a <a>" do
        html = '<a href="/about" class="something" id="some-id">Link text</a>'
        expect(described_class.call(html)).to eq('<a href="/about">Link text</a>')
      end

      it "strips out everything but title for a <abbr>" do
        html = '<abbr title="the abbreviation title" id="some-id" class="some class">XYZ</abbr>'
        expect(described_class.call(html)).to eq('<abbr title="the abbreviation title">XYZ</abbr>')
      end

      it "strips out all attributes for other nodes" do
        html = '<p class="some-class" id="some-id" data-something="data">Some text</p>'
        expect(described_class.call(html)).to eq("<p>Some text</p>")
      end
    end

    it "removes h1 elements" do
      html = <<~HTML
        <h1>Will be removed</h1>
        <h2>Won't be removed</h2>
      HTML

      expect(described_class.call(html))
        .to eq("\n<h2>Won't be removed</h2>\n")
    end

    it "extracts the contents from a number of block level elements to create a flat structure" do
      input = <<~HTML
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

      expected_output = <<~HTML
        <h2>First subheading</h2>
        <p>First paragraph under subheading</p>
        <p>Second paragraph under subheading</p>
        <h2>Second subheading</h2>
        <p>Another paragraph under the second subheading</p>
        <h2>Third subheading</h2>
        <p>Paragraph under third subheading</p>
      HTML

      expect(described_class.call(input).squish).to eq(expected_output.squish)
    end
  end
end
