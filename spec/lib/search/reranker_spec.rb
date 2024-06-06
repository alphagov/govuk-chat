RSpec.describe Search::Reranker do
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
      allow(Rails.configuration.search).to receive(:document_type_weightings).and_return({
        "guide" => 2.0, "export_health_certificate" => 0.5
      })
    end

    it "returns a Search::ResultsForQuestion::ResultSet" do
      expect(described_class.call(chunked_content_results)).to all(be_a(Search::ResultsForQuestion::WeightedResult))
    end

    it "returns results sorted by weighted_score" do
      expect(described_class.call(chunked_content_results).map { |r| [r.document_type, r.weighted_score] }).to eq(
        [
          ["guide", 0.5], # doc type weighting of 2.0
          ["form", 0.25], # not defined - default weighting of 1.0
          ["export_health_certificate", 0.125], # doc type weighting of 0.5
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
