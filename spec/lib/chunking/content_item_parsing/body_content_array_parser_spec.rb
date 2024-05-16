RSpec.describe Chunking::ContentItemParsing::BodyContentArrayParser do
  include ContentItemParserExamples
  it_behaves_like "a chunking content item parser", described_class.allowed_schemas do
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

  describe ".supported_schema_and_document_type?" do
    described_class.allowed_schemas.without("specialist_document").each do |schema|
      it "returns true for '#{schema}' schema" do
        expect(described_class.supported_schema_and_document_type?(schema, "anything")).to eq(true)
      end
    end

    it "returns false for unsupported schemas" do
      expect(described_class.supported_schema_and_document_type?("unknown", "anything")).to eq(false)
    end

    described_class::ALLOWED_SPECIALIST_DOCUMENT_TYPES.each do |document_type|
      it "allows '#{document_type}' document type for 'specialist_document' schema" do
        expect(described_class.supported_schema_and_document_type?("specialist_document", document_type)).to eq(true)
      end
    end

    it "disallows other document types for specialist_document" do
      expect(described_class.supported_schema_and_document_type?("specialist_document", "anything")).to eq(false)
    end
  end

  describe ".non_indexable_content_item_reason" do
    described_class.allowed_schemas.without("specialist_document").each do |schema_name|
      it "returns nil for '#{schema_name}' schema" do
        content_item = build(:notification_content_item, schema_name:, ensure_valid: false)
        expect(described_class.non_indexable_content_item_reason(content_item)).to be_nil
      end
    end

    it "returns a message for unsupported schemas" do
      content_item = build(:notification_content_item, schema_name: "generic", ensure_valid: false)
      expect(described_class.non_indexable_content_item_reason(content_item)).to eq(
        "document type: #{content_item['document_type']} not supported for schema: generic",
      )
    end

    described_class::ALLOWED_SPECIALIST_DOCUMENT_TYPES.each do |document_type|
      it "is nil for '#{document_type}' document type for 'specialist_document' schema" do
        content_item = build(:notification_content_item, schema_name: "specialist_document", document_type:, ensure_valid: false)
        expect(described_class.non_indexable_content_item_reason(content_item)).to be_nil
      end
    end

    it "returns a message other document types for specialist_document" do
      content_item = build(:notification_content_item, schema_name: "specialist_document",
                                                       document_type: "anything", ensure_valid: false)
      expect(described_class.non_indexable_content_item_reason(content_item)).to eq("document type: anything not supported for schema: specialist_document")
    end
  end
end
