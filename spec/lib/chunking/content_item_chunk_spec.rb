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

  describe "#exact_path" do
    context "when initialised with a exact_path" do
      it "returns the exact_path" do
        instance = build(:content_item_chunk, base_path: "/base-path", exact_path: "/path")

        expect(instance.exact_path).to eq("/path")
      end
    end

    context "when not initialised with a exact_path" do
      it "returns the content item's base_path" do
        instance = build(:content_item_chunk, base_path: "/base-path")

        expect(instance.exact_path).to eq("/base-path")
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
                       exact_path: "/exact-path",
                       parent_document_type: "guide",
                       llm_instructions: "Some instructions")

      expect(instance.to_opensearch_hash)
        .to eq({
          content_id: instance.content_item["content_id"],
          locale: instance.content_item["locale"],
          base_path: instance.content_item["base_path"],
          exact_path: "/exact-path",
          document_type: instance.content_item["document_type"],
          parent_document_type: "guide",
          schema_name: instance.content_item["schema_name"],
          title: instance.content_item["title"],
          description: instance.content_item["description"],
          chunk_index: 0,
          heading_hierarchy: ["Heading 1", "Heading 2"],
          html_content: "<p>Content</p>",
          plain_content: instance.plain_content,
          digest: instance.digest,
          llm_instructions: "Some instructions",
        })
    end
  end

  describe "#inspect" do
    it "returns a string representation of the object" do
      instance = build(:content_item_chunk,
                       html_content: "<p>Content</p>",
                       heading_hierarchy: ["Heading 1", "Heading 2"],
                       chunk_index: 0,
                       description: "Description",
                       parent_document_type: "parent",
                       llm_instructions: "Some instructions")

      # rstrip to remove the HEREDOC's trailing new line
      expect(instance.inspect).to eq(<<~HEREDOC.rstrip)
        Chunking::ContentItemChunk(
        html_content: "<p>Content</p>"
        heading_hierarchy: ["Heading 1", "Heading 2"]
        chunk_index: 0
        content_id: "#{instance.content_item['content_id']}"
        locale: "#{instance.content_item['locale']}"
        title: "#{instance.content_item['title']}"
        description: "Description"
        base_path: "#{instance.content_item['base_path']}"
        exact_path: "#{instance.content_item['base_path']}"
        document_type: "#{instance.content_item['document_type']}"
        parent_document_type: "parent"
        schema_name: "#{instance.content_item['schema_name']}"
        llm_instructions: "Some instructions"
        )
      HEREDOC
    end
  end

  describe "#parent_document_type" do
    it "returns the document_type of the first parent in the expanded_links" do
      instance = build(:content_item_chunk, parent_document_type: "guide")

      expect(instance.parent_document_type).to eq("guide")
    end

    it "returns nil if there are no parents in the expanded_links" do
      instance = build(:content_item_chunk, parent_document_type: nil)

      expect(instance.parent_document_type).to be_nil
    end
  end
end
