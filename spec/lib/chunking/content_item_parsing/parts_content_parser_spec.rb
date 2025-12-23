RSpec.describe Chunking::ContentItemParsing::PartsContentParser do
  describe ".call" do
    it "converts the array of parts into an array of chunks" do
      parts = [
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
      content_item = build(:notification_content_item,
                           schema_name: "guide",
                           base_path: "/my-guide",
                           details_merge: { "parts" => parts })

      chunk_1, chunk_2, chunk_3 = described_class.call(content_item)

      expect(chunk_1).to have_attributes(html_content: "<p>Content 1</p>",
                                         heading_hierarchy: ["Part 1", "Heading 1"],
                                         chunk_index: 0,
                                         exact_path: "/my-guide#heading-1")

      expect(chunk_2).to have_attributes(html_content: "<p>Content 2</p>",
                                         heading_hierarchy: ["Part 1", "Heading 2"],
                                         chunk_index: 1,
                                         exact_path: "/my-guide#heading-2")

      expect(chunk_3).to have_attributes(html_content: "<p>Content</p>",
                                         heading_hierarchy: ["Part 2"],
                                         chunk_index: 2,
                                         exact_path: "/my-guide/slug-2")
    end

    it "raises an error when a part lacks a text/html field" do
      parts = [
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

      content_item = build(:notification_content_item,
                           schema_name: "guide",
                           details_merge: { "parts" => parts })

      expect { described_class.call(content_item) }
        .to raise_error("content type text/html not found in schema: guide")
    end
  end
end
