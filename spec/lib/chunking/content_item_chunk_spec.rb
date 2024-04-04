RSpec.describe Chunking::ContentItemChunk do
  let(:content_item) do
    schema = GovukSchemas::Schema.find(notification_schema: "generic")
    GovukSchemas::RandomExample.new(schema:).payload
  end

  describe "#plain_content" do
    it "combines title, headings and HTML stripped content" do
      content_item["title"] = "Title"
      instance = described_class.new(content_item:,
                                     html_content: "<p>Content</p>",
                                     heading_hierachy: ["Heading 1", "Heading 2"],
                                     chunk_index: 0)

      expect(instance.plain_content).to eq("Title\nHeading 1\nHeading 2\nContent")
    end
  end

  describe "#url" do
    context "when initialised with a chunk_url" do
      it "returns the chunk_url" do
        instance = described_class.new(content_item:,
                                       html_content: "<p>Content</p>",
                                       heading_hierachy: ["Heading 1", "Heading 2"],
                                       chunk_index: 0,
                                       chunk_url: "/path")

        expect(instance.url).to eq("/path")
      end
    end

    context "when not initialised with a chunk_url" do
      it "returns the content item's base_path" do
        content_item["base_path"] = "/base-path"
        instance = described_class.new(content_item:,
                                       html_content: "<p>Content</p>",
                                       heading_hierachy: ["Heading 1", "Heading 2"],
                                       chunk_index: 0)

        expect(instance.url).to eq("/base-path")
      end
    end
  end

  describe "#digest" do
    it "returns a 256 bit hex digest that hashs the contents of this chunk" do
      instance = described_class.new(content_item:,
                                     html_content: "<p>Content</p>",
                                     heading_hierachy: ["Heading 1", "Heading 2"],
                                     chunk_index: 0)

      digest = instance.digest
      expect(digest).to match(/\A[[:xdigit:]]{64}\z/) # a 256 bit hash is 64 chars long
    end
  end

  describe "#inspect" do
    it "returns a string representation of the object" do
      instance = described_class.new(content_item:,
                                     html_content: "<p>Content</p>",
                                     heading_hierachy: ["Heading 1", "Heading 2"],
                                     chunk_index: 0)

      # rstrip to remove the HEREDOC's trailing new line
      expect(instance.inspect).to eq(<<~HEREDOC.rstrip)
        Chunking::ContentItemChunk(
        html_content: "<p>Content</p>"
        heading_hierachy: ["Heading 1", "Heading 2"]
        chunk_index: 0
        url: "#{content_item['base_path']}"
        content_id: "#{content_item['content_id']}"
        locale: "#{content_item['locale']}"
        title: "#{content_item['title']}"
        base_path: "#{content_item['base_path']}"
        document_type: "#{content_item['document_type']}"
        )
      HEREDOC
    end
  end
end
