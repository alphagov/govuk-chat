RSpec.describe Chunking::ContentItemParsing::BodyContentParser do
  include ContentItemParserExamples
  it_behaves_like "a chunking content item parser" do
    let(:content_item) { build(:notification_content_item, body: "<p>Content</p>", ensure_valid: false) }
  end

  describe ".call" do
    it "returns chunks for a HTML body field" do
      body = '<h2 id="heading-1">Heading 1</h2><p>Content 1</p><h2 id="heading-2">Heading 2</h2><p>Content 2</p>'
      content_item = build(:notification_content_item, base_path: "/path", body:, ensure_valid: false)

      chunk_1, chunk_2 = described_class.call(content_item)

      expect(chunk_1).to have_attributes(html_content: "<p>Content 1</p>",
                                         heading_hierarchy: ["Heading 1"],
                                         chunk_index: 0,
                                         url: "/path#heading-1")

      expect(chunk_2).to have_attributes(html_content: "<p>Content 2</p>",
                                         heading_hierarchy: ["Heading 2"],
                                         chunk_index: 1,
                                         url: "/path#heading-2")
    end

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
    it "returns true for schemas that don't care about document type" do
      described_class::ALLOWED_SCHEMAS.each do |schema|
        expect(described_class.supported_schema_and_document_type?(schema, "anything")).to eq(true)
      end
    end

    it "returns false for unsupported schemas" do
      expect(described_class.supported_schema_and_document_type?("unknown", "anything")).to eq(false)
    end

    %w[correspondence decision].each do |document_type|
      it "rejects '#{document_type}' document type for 'publication' schema" do
        expect(described_class.supported_schema_and_document_type?("publication", document_type)).to eq(false)
      end
    end

    it "allows other document types for 'publication' schema" do
      %w[anything anything_else].each do |document_type|
        expect(described_class.supported_schema_and_document_type?("publication", document_type)).to eq(true)
      end
    end
  end
end
