RSpec.describe Chunking::ContentItemChunk do
  describe "#id" do
    it "returns a deterministic id based on the content_id, locale and chunk_index" do
      content_id = SecureRandom.uuid
      instance = build(:content_item_chunk, content_id:, locale: "en", chunk_index: 1)

      expect(instance.id).to eq("#{content_id}_en_1")
    end
  end

  describe "#plain_content" do
    it "combines title, description, headings and HTML stripped content" do
      instance = build(:content_item_chunk,
                       title: "Title",
                       description: "Description",
                       html_content: "<p>Content</p>",
                       heading_hierarchy: ["Heading 1", "Heading 2"])

      expect(instance.plain_content).to eq("Title\nHeading 1\nHeading 2\nContent\nDescription")
    end

    it "copes with a nil description" do
      instance = build(:content_item_chunk,
                       title: "Title",
                       description: nil,
                       html_content: "<p>Content</p>",
                       heading_hierarchy: ["Heading 1", "Heading 2"])

      expect(instance.plain_content).to eq("Title\nHeading 1\nHeading 2\nContent")
    end
  end

  describe "#url" do
    context "when initialised with a chunk_url" do
      it "returns the chunk_url" do
        instance = build(:content_item_chunk, base_path: "/base-path", chunk_url: "/path")

        expect(instance.url).to eq("/path")
      end
    end

    context "when not initialised with a chunk_url" do
      it "returns the content item's base_path" do
        instance = build(:content_item_chunk, base_path: "/base-path")

        expect(instance.url).to eq("/base-path")
      end
    end
  end

  describe "#digest" do
    it "returns a 256 bit hex digest that hashs the contents of this chunk" do
      instance = build(:content_item_chunk)

      expect(instance.digest).to match(/\A[[:xdigit:]]{64}\z/) # a 256 bit hash is 64 chars long
    end
  end

  describe "#to_opensearch_hash" do
    it "returns a hash that is structured for the chunked content OpenSearch index" do
      instance = build(:content_item_chunk,
                       html_content: "<p>Content</p>",
                       heading_hierarchy: ["Heading 1", "Heading 2"],
                       chunk_index: 0,
                       chunk_url: "/chunk-url")

      expect(instance.to_opensearch_hash)
        .to eq({
          content_id: instance.content_item["content_id"],
          locale: instance.content_item["locale"],
          base_path: instance.content_item["base_path"],
          document_type: instance.content_item["document_type"],
          title: instance.content_item["title"],
          description: instance.content_item["description"],
          url: "/chunk-url",
          chunk_index: 0,
          heading_hierarchy: ["Heading 1", "Heading 2"],
          html_content: "<p>Content</p>",
          plain_content: instance.plain_content,
          digest: instance.digest,
        })
    end
  end

  describe "#inspect" do
    it "returns a string representation of the object" do
      instance = build(:content_item_chunk,
                       html_content: "<p>Content</p>",
                       heading_hierarchy: ["Heading 1", "Heading 2"],
                       chunk_index: 0,
                       description: "Description")

      # rstrip to remove the HEREDOC's trailing new line
      expect(instance.inspect).to eq(<<~HEREDOC.rstrip)
        Chunking::ContentItemChunk(
        html_content: "<p>Content</p>"
        heading_hierarchy: ["Heading 1", "Heading 2"]
        chunk_index: 0
        url: "#{instance.content_item['base_path']}"
        content_id: "#{instance.content_item['content_id']}"
        locale: "#{instance.content_item['locale']}"
        title: "#{instance.content_item['title']}"
        description: "Description"
        base_path: "#{instance.content_item['base_path']}"
        document_type: "#{instance.content_item['document_type']}"
        )
      HEREDOC
    end
  end
end
