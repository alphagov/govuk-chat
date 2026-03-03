RSpec.describe Search::ResultsForQuestion::WeightedResult do
  let(:score) { 1.7 }
  let(:weighted_score) { 0.85 }
  let(:weighting) { 0.5 }
  let(:result) do
    Search::ChunkedContentRepository::Result.new(score:, schema_name: "guide", document_type: "guide")
  end
  let(:reranked_result) { described_class.new(result:, weighted_score:, weighting:) }

  it "returns the weighted_score" do
    expect(reranked_result.weighted_score).to eq(weighted_score)
  end

  it "returns the weighting" do
    expect(reranked_result.weighting).to eq(weighting)
  end

  it "delegates other methods to the source object" do
    expect(reranked_result.score).to eq(score)
  end

  it "describes the score calculation" do
    expect(reranked_result.score_calculation).to eq("1.7 * 0.5 = 0.85")
  end

  describe "#chunk_uid" do
    it "returns a unique identifier for the chunk based on content_id, locale, chunk_index and digest" do
      result = Search::ChunkedContentRepository::Result.new(
        content_id: "abc123",
        locale: "en",
        chunk_index: 2,
        digest: "def456",
      )
      instance = described_class.new(result:, weighted_score:, weighting:)

      expect(instance.chunk_uid)
        .to eq("#{result.content_id}_#{result.locale}_#{result.chunk_index}_#{result.digest}")
    end
  end
end
