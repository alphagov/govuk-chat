RSpec.describe Search::ChunkedContentRepository, :chunked_content_index do
  let(:repository) { described_class.new }

  describe "#delete_by_base_path" do
    it "deletes all items of a particular base_path" do
      populate_chunked_content_index([{ base_path: "/a" },
                                      { base_path: "/a" },
                                      { base_path: "/b" }])

      expect { repository.delete_by_base_path("/a") }
        .to change { repository.count(term: { base_path: "/a" }) }
        .by(-2)
    end
  end
end
