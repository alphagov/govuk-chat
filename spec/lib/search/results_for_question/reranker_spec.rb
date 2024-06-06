RSpec.describe Search::ResultsForQuestion::Reranker do
  describe "reranking configuration" do
    it "only contains keys that are valid document types" do
      expect(Rails.configuration.search.document_type_weightings.keys - GovukSchemas::DocumentTypes.valid_document_types).to be_empty
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

    before do
      stub_const("Search::ResultsForQuestion::Reranker::DOCUMENT_TYPE_WEIGHTINGS", {
        "guide" => 4.0, "export_health_certificate" => 0.8
      })
    end

    it "returns a Search::ResultsForQuestion::ResultSet" do
      expect(described_class.call(chunked_content_results)).to all(be_a(Search::ResultsForQuestion::WeightedResult))
    end

    it "returns results sorted by weighted_score" do
      expect(described_class.call(chunked_content_results).map { |r| [r.document_type, r.weighted_score] }).to eq(
        [
          ["guide", 1.0], # doc type weighting of 4.0
          ["form", 0.25], # not defined - default weighting of 1.0
          ["export_health_certificate", 0.2], # doc type weighting of 0.8
        ],
      )
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
        expect(described_class.call(chunked_content_results).map { |r| [r.parent_document_type, r.weighted_score] }).to eq(
          [
            ["guide", 1.0], # doc type weighting of 4.0
            ["form", 0.25], # not defined - default weighting of 1.0
            ["export_health_certificate", 0.2], # doc type weighting of 0.8
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
