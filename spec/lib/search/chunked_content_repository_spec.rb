RSpec.describe Search::ChunkedContentRepository, :chunked_content_index do
  let(:repository) { described_class.new }

  describe "#delete_by_base_path" do
    before do
      populate_chunked_content_index([{ base_path: "/a" },
                                      { base_path: "/a" },
                                      { base_path: "/b" }])
    end

    it "deletes all items of a particular base_path" do
      expect { repository.delete_by_base_path("/a") }
        .to change { repository.count(term: { base_path: "/a" }) }
        .by(-2)
    end

    it "returns the number of items it deleted" do
      expect(repository.delete_by_base_path("/a")).to eq(2)
    end
  end

  describe "#bulk_index" do
    it "can combine indexing and deleting records" do
      populate_chunked_content_index([{ _id: "id1", base_path: "/a" }])

      documents_to_index = [{ _id: "id2", base_path: "/b" }]
      document_ids_to_delete = %w[id1]

      expect { repository.bulk_index(documents_to_index:, document_ids_to_delete:) }
        .to change { repository.count(term: { base_path: "/b" }) }
        .by(1)
        .and change { repository.count(term: { base_path: "/a" }) }
        .by(-1)
    end

    it "can insert new records" do
      documents_to_index = [{ base_path: "/c" }, { base_path: "/c" }]

      expect { repository.bulk_index(documents_to_index:) }
        .to change { repository.count(term: { base_path: "/c" }) }
        .by(2)
    end

    it "can update existing records" do
      populate_chunked_content_index([{ _id: "id1", base_path: "/a" }])

      documents_to_index = [{ _id: "id1", base_path: "/b" }]

      expect { repository.bulk_index(documents_to_index:) }
        .to change { repository.count(term: { base_path: "/b" }) }
        .by(1)
        .and change { repository.count(term: { base_path: "/a" }) }
        .by(-1)
    end
  end
end
