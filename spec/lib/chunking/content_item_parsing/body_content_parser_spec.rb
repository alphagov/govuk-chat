RSpec.describe Chunking::ContentItemParsing::BodyContentParser do
  include ContentItemParserExamples

  let(:content_item) do
    schema = GovukSchemas::Schema.find(notification_schema: "generic")
    GovukSchemas::RandomExample.new(schema:).payload.tap do |item|
      item["details"]["body"] = "<p>Content</p>"
    end
  end

  it_behaves_like "a chunking content item parser"

  describe ".call" do
    it "returns chunks for a HTML body field" do
      content_item["base_path"] = "/path"
      content_item["details"]["body"] = '<h2 id="heading-1">Heading 1</h2><p>Content 1</p><h2 id="heading-2">Heading 2</h2><p>Content 2</p>'

      chunk_1, chunk_2 = described_class.call(content_item)

      expect(chunk_1).to have_attributes(html_content: "<p>Content 1</p>",
                                         heading_hierachy: ["Heading 1"],
                                         chunk_index: 0,
                                         url: "/path#heading-1")

      expect(chunk_2).to have_attributes(html_content: "<p>Content 2</p>",
                                         heading_hierachy: ["Heading 2"],
                                         chunk_index: 1,
                                         url: "/path#heading-2")
    end

    it "raises an error if there is not a body field in the details hash" do
      content_item["details"] = {}

      expect { described_class.call(content_item) }
        .to raise_error("nil value in details hash for body in schema: generic")
    end

    it "returns chunks for a multiple content types body field" do
      content_item["base_path"] = "/path"
      content_item["details"]["body"] = [
        {
          "content_type" => "text/html",
          "content" => "<p>Content</p>",
        },
        {
          "content_type" => "text/govspeak",
          "content" => "Content",
        },
      ]

      chunk, = described_class.call(content_item)

      expect(chunk).to have_attributes(html_content: "<p>Content</p>",
                                       heading_hierachy: [],
                                       chunk_index: 0,
                                       url: "/path")
    end

    it "raises an error when there is not a text/html content type in a multiple content types body field" do
      content_item["details"]["body"] = [
        {
          "content_type" => "text/govspeak",
          "content" => "Content",
        },
      ]

      expect { described_class.call(content_item) }
        .to raise_error("content type text/html not found in schema: generic")
    end
  end
end
