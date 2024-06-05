RSpec.describe Search::Reranker do
  describe "reranking configuration" do
    it "only contains keys that are valid document types" do
      expect(Rails.configuration.chunked_content_reranking.keys - GovukSchemas::DocumentTypes.valid_document_types).to be_empty
    end
  end

  describe ".call" do
    let(:chunked_content_results) do
      [
        build_chunked_content_result(score: 0.25, document_type: "form"),
        build_chunked_content_result(score: 0.25, document_type: "guide"),
        build_chunked_content_result(score: 0.25, document_type: "export_health_certificate"),
      ]
    end
    let(:result_score_threshold) { 0.1 }

    before do
      allow(Rails.configuration.search).to receive(:result_score_threshold).and_return(result_score_threshold)
      allow(Rails.configuration).to receive(:chunked_content_reranking).and_return({
        "guide" => 2.0, "export_health_certificate" => 0.5
      })
    end

    it "returns a Search::ResultsForQuestion::ResultSet" do
      expect(described_class.call(chunked_content_results)).to be_a(Search::ResultsForQuestion::ResultSet)
    end

    it "returns results as Search::ResultsForQuestion::Result" do
      expect(described_class.call(chunked_content_results).results).to all(be_a(Search::ResultsForQuestion::Result))
    end

    it "returns results sorted by reranked_score" do
      expect(described_class.call(chunked_content_results).results.map { |r| [r.document_type, r.reranked_score] }).to eq(
        [
          ["guide", 0.5], # doc type weighting of 2.0
          ["form", 0.25], # not defined - default weighting of 1.0
          ["export_health_certificate", 0.125], # doc type weighting of 0.5
        ],
      )
    end

    context "when the reranked score doesn't meet the configured threshold" do
      let(:result_score_threshold) { 0.5 }

      it "has results with reranked_score >= threshold" do
        expect(described_class.call(chunked_content_results).results
          .map { |r| [r.document_type, r.reranked_score] }).to eq([["guide", 0.5]])
      end

      it "has the other results in rejected_results" do
        expect(described_class.call(chunked_content_results).rejected_results
          .map { |r| [r.document_type, r.reranked_score] }).to eq([["form", 0.25], ["export_health_certificate", 0.125]])
      end
    end

    context "when there are more results than the configured max" do
      before do
        allow(Rails.configuration.search).to receive(:max_number_of_results).and_return(2)
      end

      it "has the top N results" do
        expect(described_class.call(chunked_content_results).results
          .map { |r| [r.document_type, r.reranked_score] }).to eq([["guide", 0.5], ["form", 0.25]])
      end

      it "has the other results in rejected_results" do
        expect(described_class.call(chunked_content_results).rejected_results
          .map { |r| [r.document_type, r.reranked_score] }).to eq([["export_health_certificate", 0.125]])
      end
    end

    context "when the parent_document_type is html_publication" do
      let(:chunked_content_results) do
        [
          build_chunked_content_result(score: 0.25, document_type: "html_publication", parent_document_type: "form"),
          build_chunked_content_result(score: 0.25, document_type: "html_publication", parent_document_type: "guide"),
          build_chunked_content_result(score: 0.25, document_type: "html_publication", parent_document_type: "export_health_certificate"),
        ]
      end

      it "returns results sorted based on parent_document_type" do
        expect(described_class.call(chunked_content_results).results.map { |r| [r.parent_document_type, r.reranked_score] }).to eq(
          [
            ["guide", 0.5], # doc type weighting of 2.0
            ["form", 0.25], # doc type weighting of 1.0
            ["export_health_certificate", 0.125], # doc type weighting of 0.5
          ],
        )
      end
    end
  end

  def build_chunked_content_result(attributes)
    defaults = build(:chunked_content_record).except(:openai_embedding)
    Search::ChunkedContentRepository::Result.new(**defaults.merge(attributes))
  end
end
