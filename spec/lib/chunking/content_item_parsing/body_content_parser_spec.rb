RSpec.describe Chunking::ContentItemParsing::BodyContentParser do
  include ContentItemParserExamples
  schemas = described_class.allowed_schemas.map do |schema_name|
    next { schema_name => "guidance" } if schema_name == "publication"
    next { schema_name => "oral_statement" } if schema_name == "speech"

    schema_name
  end

  it_behaves_like "a chunking content item parser", schemas do
    let(:content_item) { build(:notification_content_item, body: "<p>Content</p>", schema_name:) }
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
  end

  describe ".non_indexable_content_item_reason" do
    it "returns nil for schemas that don't care about document type" do
      described_class.allowed_schemas.without("publication", "speech").each do |schema_name|
        content_item = build(:notification_content_item, schema_name:)
        expect(described_class.non_indexable_content_item_reason(content_item)).to be_nil
      end
    end

    %w[correspondence decision].each do |document_type|
      it "rejects '#{document_type}' document type for 'publication' schema" do
        content_item = build(:notification_content_item, schema_name: "publication", document_type:, ensure_valid: false)
        expect(described_class.non_indexable_content_item_reason(content_item)).to eq(
          "document type: #{document_type} not supported for schema: publication",
        )
      end

      it "allows '#{document_type}' document type for other schemas" do
        content_item = build(:notification_content_item, schema_name: "consultation", document_type:, ensure_valid: false)
        expect(described_class.non_indexable_content_item_reason(content_item)).to be_nil
      end
    end

    %w[oral_statement written_statement].each do |document_type|
      it "allows #{document_type} document type for 'speech' schema" do
        content_item = build(:notification_content_item, schema_name: "speech", document_type:, ensure_valid: false)
        expect(described_class.non_indexable_content_item_reason(content_item)).to be_nil
      end
    end

    it "disallows other document types for speech" do
      content_item = build(:notification_content_item, schema_name: "speech", document_type: "anything", ensure_valid: false)
      expect(described_class.non_indexable_content_item_reason(content_item)).to eq(
        "document type: anything not supported for schema: speech",
      )
    end

    it "allows other document types for 'publication' schema" do
      %w[anything anything_else].each do |document_type|
        content_item = build(:notification_content_item, schema_name: "publication", document_type:, ensure_valid: false)
        expect(described_class.non_indexable_content_item_reason(content_item)).to be_nil
      end
    end
  end
end
