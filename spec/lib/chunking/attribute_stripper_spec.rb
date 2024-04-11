RSpec.describe Chunking::AttributeStripper do
  describe ".call" do
    %w[h2 h3 h4 h5 h6].each do |element|
      it "strips out everything but id for a <#{element}>" do
        html = %(<#{element} class="something" id="some-id">Heading</#{element}>)
        node = Nokogiri::HTML::DocumentFragment.parse(html).children.first
        described_class.call(node)
        expect(node.to_html).to eq(%(<#{element} id="some-id">Heading</#{element}>))
      end
    end

    it "strips out everything but href for a <a>" do
      html = '<a href="/about" class="something" id="some-id">Link text</a>'
      node = Nokogiri::HTML::DocumentFragment.parse(html).children.first
      described_class.call(node)
      expect(node.to_html).to eq('<a href="/about">Link text</a>')
    end

    it "strips out everything but title for a <abbr>" do
      html = '<abbr title="the abbreviation title" id="some-id" class="some class">XYZ</abbr>'
      node = Nokogiri::HTML::DocumentFragment.parse(html).children.first
      described_class.call(node)
      expect(node.to_html).to eq('<abbr title="the abbreviation title">XYZ</abbr>')
    end

    it "strips out all attributes for other nodes" do
      html = '<p class="some-class" id="some-id" data-something="data">Some text</p>'
      node = Nokogiri::HTML::DocumentFragment.parse(html).children.first
      described_class.call(node)
      expect(node.to_html).to eq("<p>Some text</p>")
    end
  end
end
