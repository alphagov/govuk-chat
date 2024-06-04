RSpec.describe Search::ResultsForQuestion::Result do
  let(:score) { 0.23 }
  let(:reranked_score) { 0.85 }
  let(:result) { Search::ChunkedContentRepository::Result.new(score:) }
  let(:reranked_result) { described_class.new(result:, reranked_score:) }

  it "returns the reranked_score" do
    expect(reranked_result.reranked_score).to eq(reranked_score)
  end

  it "delegates other methods to the source object" do
    expect(reranked_result.score).to eq(score)
  end
end
