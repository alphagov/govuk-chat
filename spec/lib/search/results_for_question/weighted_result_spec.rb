RSpec.describe Search::ResultsForQuestion::WeightedResult do
  let(:score) { 0.23 }
  let(:weighted_score) { 0.85 }
  let(:result) { Search::ChunkedContentRepository::Result.new(score:) }
  let(:reranked_result) { described_class.new(result:, weighted_score:) }

  it "returns the weighted_score" do
    expect(reranked_result.weighted_score).to eq(weighted_score)
  end

  it "delegates other methods to the source object" do
    expect(reranked_result.score).to eq(score)
  end
end
