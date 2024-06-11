RSpec.describe Search::ResultsForQuestion::WeightedResult do
  let(:score) { 1.7 }
  let(:weighted_score) { 0.85 }
  let(:result) { Search::ChunkedContentRepository::Result.new(score:, document_type: "guide") }
  let(:reranked_result) { described_class.new(result:, weighted_score:) }

  before do
    stub_const("Search::ResultsForQuestion::Reranker::DOCUMENT_TYPE_WEIGHTINGS", { "guide" => 0.5 })
  end

  it "returns the weighted_score" do
    expect(reranked_result.weighted_score).to eq(weighted_score)
  end

  it "delegates other methods to the source object" do
    expect(reranked_result.score).to eq(score)
  end

  it "describes the score calculation" do
    expect(reranked_result.score_calculation).to eq("1.7 * 0.5 = 0.85")
  end
end
