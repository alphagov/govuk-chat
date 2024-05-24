RSpec.describe Chunking::ContentItemParsing::BodyContentParser do
  include ContentItemParserExamples

  it_behaves_like "a chunking content item parser", described_class.allowed_schemas do
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
                                         url: "/path#heading-1")

      expect(chunk_2).to have_attributes(html_content: "<p>Content 2</p>",
                                         heading_hierarchy: ["Heading 2"],
                                         chunk_index: 1,
                                         url: "/path#heading-2")
    end

    it "raises an error if there is not a body field in the details hash" do
      content_item = build(:notification_content_item, details: {})

      expect { described_class.call(content_item) }
        .to raise_error("nil value in details hash for body in schema: generic")
    end
  end

  describe ".non_indexable_content_item_reason" do
    it "returns nil for a schema that doesn't care about document type" do
      content_item = build(:notification_content_item, schema_name: "call_for_evidence")
      expect(described_class.non_indexable_content_item_reason(content_item)).to be_nil
    end

    %w[correspondence decision].each do |document_type|
      it "rejects '#{document_type}' document type for 'publication' schema" do
        content_item = build(:notification_content_item, schema_name: "publication", document_type:)
        expect(described_class.non_indexable_content_item_reason(content_item)).to eq(
          "document type: #{document_type} not supported for schema: publication",
        )
      end
    end

    it "allows other document types for 'publication' schema" do
      content_item = build(:notification_content_item, schema_name: "publication", document_type: "guidance")
      expect(described_class.non_indexable_content_item_reason(content_item)).to be_nil
    end

    %w[oral_statement written_statement].each do |document_type|
      it "allows #{document_type} document type for the speech schema" do
        content_item = build(:notification_content_item, schema_name: "speech", document_type:)
        expect(described_class.non_indexable_content_item_reason(content_item)).to be_nil
      end
    end

    it "disallows other document types for the speech schema" do
      content_item = build(:notification_content_item, schema_name: "speech", document_type: "speech")
      expect(described_class.non_indexable_content_item_reason(content_item)).to eq(
        "document type: speech not supported for schema: speech",
      )
    end

    it "return nil for an allowed corporate information page" do
      content_item = build(:notification_content_item, schema_name: "corporate_information_page", document_type: "modern_slavery_statement")
      expect(described_class.non_indexable_content_item_reason(content_item)).to be_nil
    end

    it "disallows other document types for corporate_information_page" do
      content_item = build(:notification_content_item, schema_name: "corporate_information_page", document_type: "equality_and_diversity")
      expect(described_class.non_indexable_content_item_reason(content_item)).to eq(
        "document type: equality_and_diversity not supported for schema: corporate_information_page",
      )
    end

    context "when the schema is html_publication" do
      context "when the content item has no parent link" do
        let(:content_item) { build(:notification_content_item, schema_name: "html_publication", parent_document_type: nil) }

        it "returns error that parent is missing" do
          expect(described_class.non_indexable_content_item_reason(content_item)).to eq(
            "HTML publication lacks a parent document_type",
          )
        end
      end

      context "when the content_item has a parent link" do
        described_class::EXCLUDED_PUBLICATION_DOCUMENT_TYPES.each do |document_type|
          it "doesn't support parsing a #{document_type} with a message" do
            content_item = build(:notification_content_item, schema_name: "html_publication", parent_document_type: document_type)
            expect(described_class.non_indexable_content_item_reason(content_item)).to eq(
              "html_publication items with parent document type: #{document_type} are not supported",
            )
          end
        end
      end
    end
  end
end
