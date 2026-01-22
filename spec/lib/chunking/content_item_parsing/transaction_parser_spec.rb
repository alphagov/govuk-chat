RSpec.describe Chunking::ContentItemParsing::TransactionParser do
  describe ".call" do
    it "uses the relevant fields for chunking 'transaction' content types" do
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

    it "uses the relevant fields for chunking 'local_transaction' content types" do
      details = {
        "introduction" => [
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
        "need_to_know" => [
          {
            "content_type" => "text/html",
            "content" => "<h2>Heading 3</h2><p>Content 3</p>",
          },
        ],

      }
      content_item = build(:notification_content_item,
                           :local_transaction,
                           details_merge: details)

      chunk_1, chunk_2, chunk_3 = described_class.call(content_item)

      expect(chunk_1).to have_attributes(html_content: "<p>Content 1</p>")
      expect(chunk_2).to have_attributes(html_content: "<p>Content 2</p>")
      expect(chunk_3).to have_attributes(html_content: "<p>Content 3</p>")
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
end
