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
end
