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

    let(:content_item) { build(:notification_content_item, schema_name:, body:) }
  end

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
                                       exact_path: "/path")
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

  describe ".non_indexable_content_item_reason" do
    it "returns nil for an allowed specialist_document schema" do
      content_item = build(:notification_content_item, schema_name: "specialist_document", document_type: "business_finance_support_scheme")
      expect(described_class.non_indexable_content_item_reason(content_item)).to be_nil
    end

    it "returns a message other document types for specialist_document" do
      content_item = build(:notification_content_item, schema_name: "specialist_document",
                                                       document_type: "anything", ensure_valid: false)
      expect(described_class.non_indexable_content_item_reason(content_item)).to eq("document type: anything not supported for schema: specialist_document")
    end

    it "raises an error if the schema is not configured to use this parser" do
      content_item = build(:notification_content_item, schema_name: "guide", document_type: "guide")

      expect { described_class.non_indexable_content_item_reason(content_item) }.to raise_error(
        "#{content_item['schema_name']} cannot be parsed by #{described_class.name}",
      )
    end
  end
end
