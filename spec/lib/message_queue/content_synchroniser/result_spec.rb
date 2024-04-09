RSpec.describe MessageQueue::ContentSynchroniser::Result do
  describe "#to_s" do
    context "when a skip index reason is not given" do
      it "returns a sentence explaining the number of chunks created, updated, skipped and deleted" do
        instance = described_class.new(chunks_created: 1,
                                       chunks_updated: 2,
                                       chunks_skipped: 3,
                                       chunks_deleted: 0)

        expect(instance.to_s).to eq("1 chunk newly inserted, 2 chunks updated, 3 chunks didn't need updating, 0 chunks deleted")
      end
    end

    context "when given a skip index reason" do
      it "returns a sentence explaining the skip reason and the number of chunks deleted" do
        instance = described_class.new(chunks_deleted: 1,
                                       skip_index_reason: "content is broken")
        expect(instance.to_s).to eq("content not indexed (content is broken), 1 chunk deleted")
      end
    end
  end
end
