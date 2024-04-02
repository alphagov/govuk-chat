RSpec.describe Chunking::AttributeStripper do
  describe ".call" do
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
