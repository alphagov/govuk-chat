RSpec.describe Chunking::ContentItemParsing::BodyContentArrayParser do
  include ContentItemParserExamples
  it_behaves_like "a chunking content item parser" do
    let(:body) do
      [
        {
          "content_type" => "text/html",
          "content" => "<p>Content</p>",
        },
        {
          "content_type" => "text/govspeak",
          "content" => "Content",
        },
      ]
    end

    let(:content_item) { build(:notification_content_item, body:, ensure_valid: false) }
  end

  it_behaves_like "a parser that allows .allowed_schemas"

  describe ".call" do
    it "raises an error if there is not a body field in the details hash" do
      content_item = build(:notification_content_item, details: {}, ensure_valid: false)

      expect { described_class.call(content_item) }
        .to raise_error("nil value in details hash for body in schema: generic")
    end

    it "returns chunks for a multiple content types body field" do
      content_item = build(
        :notification_content_item,
        base_path: "/path",
        ensure_valid: false,
        body: [
          {
            "content_type" => "text/html",
            "content" => "<p>Content</p>",
          },
          {
            "content_type" => "text/govspeak",
            "content" => "Content",
          },
        ],
      )

      chunk, = described_class.call(content_item)

      expect(chunk).to have_attributes(html_content: "<p>Content</p>",
                                       heading_hierarchy: [],
                                       chunk_index: 0,
                                       url: "/path")
    end

    it "raises an error when there is not a text/html content type in a multiple content types body field" do
      content_item = build(
        :notification_content_item,
        ensure_valid: false,
        body: [
          {
            "content_type" => "text/govspeak",
            "content" => "Content",
          },
        ],
      )

      expect { described_class.call(content_item) }
        .to raise_error("content type text/html not found in schema: generic")
    end
  end
end
