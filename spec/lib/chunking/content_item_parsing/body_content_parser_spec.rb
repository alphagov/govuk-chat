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

  describe ".non_indexable_content_item_reason" do
    it "rejects unsupported document types for 'publication' schema" do
      content_item = build(:notification_content_item, schema_name: "publication", document_type: "correspondence")
      expect(described_class.non_indexable_content_item_reason(content_item)).to eq(
        "document type: correspondence not supported for schema: publication",
      )
    end

    it "raises an error if the schema is not configured to use this parser" do
      content_item = build(:notification_content_item, schema_name: "guide", document_type: "guide")

      expect { described_class.non_indexable_content_item_reason(content_item) }.to raise_error(
        "#{content_item['schema_name']} cannot be parsed by #{described_class.name}",
      )
    end

    it "allows other document types for 'publication' schema" do
      content_item = build(:notification_content_item, schema_name: "publication", document_type: "guidance")
      expect(described_class.non_indexable_content_item_reason(content_item)).to be_nil
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
        it "doesn't support parsing an excluded item with a message" do
          content_item = build(:notification_content_item, schema_name: "html_publication", parent_document_type: "decision")
          expect(described_class.non_indexable_content_item_reason(content_item)).to eq(
            "html_publication items with parent document type: decision are not supported",
          )
        end

        it "supports parsing other items" do
          content_item = build(:notification_content_item, schema_name: "html_publication", parent_document_type: "guidance")
          expect(described_class.non_indexable_content_item_reason(content_item)).to be_nil
        end
      end
    end
  end
end
