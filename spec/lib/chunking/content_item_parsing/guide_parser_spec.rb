RSpec.describe Chunking::ContentItemParsing::GuideParser do
  include ContentItemParserExamples

  let(:content_item) do
    schema = GovukSchemas::Schema.find(notification_schema: "guide")
    GovukSchemas::RandomExample.new(schema:).payload.tap do |item|
      item["details"]["parts"] = [
        "title" => "Part 1",
        "slug" => "slug-1",
        "body" => [
          {
            "content_type" => "text/html",
            "content" => "<p>Content</p>",
          },
        ],
      ]
    end
  end

  it_behaves_like "a chunking content item parser"

  describe ".call" do
    it "converts the array of parts into an array of chunks" do
      content_item["base_path"] = "/my-guide"
      content_item["details"]["parts"] = [
        {
          "title" => "Part 1",
          "slug" => "slug-1",
          "body" => [
            {
              "content_type" => "text/html",
              "content" => '<h2 id="heading-1">Heading 1</h2><p>Content 1</p><h2 id="heading-2">Heading 2</h2><p>Content 2</p>',
            },
            {
              "content_type" => "text/govspeak",
              "content" => "Content",
            },
          ],
        },
        {
          "title" => "Part 2",
          "slug" => "slug-2",
          "body" => [
            {
              "content_type" => "text/html",
              "content" => "<p>Content</p>",
            },
            {
              "content_type" => "text/govspeak",
              "content" => "Content",
            },
          ],
        },
      ]

      chunk_1, chunk_2, chunk_3 = described_class.call(content_item)

      expect(chunk_1).to have_attributes(html_content: "<p>Content 1</p>",
                                         heading_hierachy: ["Part 1", "Heading 1"],
                                         chunk_index: 0,
                                         url: "/my-guide/slug-1#heading-1")

      expect(chunk_2).to have_attributes(html_content: "<p>Content 2</p>",
                                         heading_hierachy: ["Part 1", "Heading 2"],
                                         chunk_index: 1,
                                         url: "/my-guide/slug-1#heading-2")

      expect(chunk_3).to have_attributes(html_content: "<p>Content</p>",
                                         heading_hierachy: ["Part 2"],
                                         chunk_index: 2,
                                         url: "/my-guide/slug-2")
    end

    it "raises an error when a details field lacks parts" do
      content_item["details"] = {}

      expect { described_class.call(content_item) }
        .to raise_error("nil value in details hash for parts in schema: guide")
    end

    it "raises an error when a part lacks a text/html field" do
      content_item["details"]["parts"] = [
        {
          "title" => "Part 1",
          "slug" => "slug-1",
          "body" => [
            {
              "content_type" => "text/govspeak",
              "content" => "Content",
            },
          ],
        },
      ]

      expect { described_class.call(content_item) }
        .to raise_error("content type text/html not found in schema: guide")
    end
  end
end
