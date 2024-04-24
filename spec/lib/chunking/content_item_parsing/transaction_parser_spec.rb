RSpec.describe Chunking::ContentItemParsing::TransactionParser do
  include ContentItemParserExamples

  it_behaves_like "a chunking content item parser" do
    let(:content_item) do
      build(
        :notification_content_item,
        schema_name: "transaction",
        details: {
          "introductory_paragraph" => [
            {
              "content_type" => "text/html",
              "content" => "<p>Content/p>",
            },
          ],
        },
      )
    end
  end

  describe ".call" do
    it "uses the introductory_paragraph, more_information, other_ways_to_apply and what_you_need_to_know fields for chunks" do
      details = {
        "introductory_paragraph" => [
          {
            "content_type" => "text/html",
            "content" => "<h2>Heading 1</h2><p>Content 1</p>",
          },
        ],
        "more_information" => [
          {
            "content_type" => "text/html",
            "content" => "<h2>Heading 2</h2><p>Content 2</p>",
          },
        ],
        "other_ways_to_apply" => [
          {
            "content_type" => "text/html",
            "content" => "<h2>Heading 3</h2><p>Content 3</p>",
          },
        ],
        "what_you_need_to_know" => [
          {
            "content_type" => "text/html",
            "content" => "<h2>Heading 4</h2><p>Content 4</p>",
          },
        ],
      }
      content_item = build(:notification_content_item,
                           schema_name: "transaction",
                           details:)

      chunk_1, chunk_2, chunk_3, chunk_4 = described_class.call(content_item)

      expect(chunk_1).to have_attributes(html_content: "<p>Content 1</p>")
      expect(chunk_2).to have_attributes(html_content: "<p>Content 2</p>")
      expect(chunk_3).to have_attributes(html_content: "<p>Content 3</p>")
      expect(chunk_4).to have_attributes(html_content: "<p>Content 4</p>")
    end

    it "copes if fields are missing" do
      details = {
        "introductory_paragraph" => [
          {
            "content_type" => "text/html",
            "content" => "<h2>Heading 1</h2><p>Content 1</p>",
          },
        ],
        "more_information" => [
          {
            "content_type" => "text/html",
            "content" => "<h2>Heading 2</h2><p>Content 2</p>",
          },
        ],
      }

      content_item = build(:notification_content_item,
                           schema_name: "transaction",
                           details:)

      chunk_1, chunk_2 = described_class.call(content_item)

      expect(chunk_1).to have_attributes(html_content: "<p>Content 1</p>")
      expect(chunk_2).to have_attributes(html_content: "<p>Content 2</p>")
    end

    it "copes if all fields are missing" do
      content_item = build(:notification_content_item,
                           schema_name: "transaction",
                           details: {})

      expect(described_class.call(content_item)).to eq([])
    end

    it "raises an error if a field lacks a text/html content type" do
      details = {
        "introductory_paragraph" => [
          {
            "content_type" => "text/govspeak",
            "content" => "Content",
          },
        ],
      }

      content_item = build(:notification_content_item,
                           schema_name: "transaction",
                           details:)

      expect { described_class.call(content_item) }
        .to raise_error("content type text/html not found in schema: transaction")
    end
  end

  describe ".supported_schema_and_document_type?" do
    it "returns true for allowed_schemas" do
      described_class.allowed_schemas.each do |schema|
        expect(described_class.supported_schema_and_document_type?(schema, "anything")).to eq(true)
      end
    end

    it "returns false for unsupported schemas" do
      expect(described_class.supported_schema_and_document_type?("unknown", "anything")).to eq(false)
    end
  end
end
