RSpec.describe Chunking::ContentItemParsing::BodyContentParser do
  include ContentItemParserExamples

  it_behaves_like "a chunking content item parser" do
    let(:content_item) { build(:notification_content_item, body: "<p>Content</p>", schema_name:) }
  end

  describe ".call" do
    it "returns chunks for a HTML body field" do
      body = '<h2 id="heading-1">Heading 1</h2><p>Content 1</p><h2 id="heading-2">Heading 2</h2><p>Content 2</p>'
      content_item = build(:notification_content_item, base_path: "/path", body:, schema_name: "news_article")

      chunk_1, chunk_2 = described_class.call(content_item)

      expect(chunk_1).to have_attributes(html_content: "<p>Content 1</p>",
                                         heading_hierarchy: ["Heading 1"],
                                         chunk_index: 0,
                                         exact_path: "/path#heading-1")

      expect(chunk_2).to have_attributes(html_content: "<p>Content 2</p>",
                                         heading_hierarchy: ["Heading 2"],
                                         chunk_index: 1,
                                         exact_path: "/path#heading-2")
    end

    it "raises an error if there is not a body field in the details hash" do
      content_item = build(:notification_content_item, details: {})

      expect { described_class.call(content_item) }
        .to raise_error("nil value in details hash for body in schema: generic")
    end
  end
end
