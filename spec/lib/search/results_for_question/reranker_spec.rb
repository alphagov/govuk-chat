RSpec.describe Search::ResultsForQuestion::Reranker do
  describe ".document_type_weighting" do
    it "returns the weight for a given document type" do
      expect(described_class.document_type_weighting("simple_smart_answer", "simple_smart_answer")).to eq(2.0)
    end

    it "returns the default weight for a given document type" do
      expect(described_class.document_type_weighting("manual", "manual")).to eq(described_class::DEFAULT_WEIGHTING)
    end

    it "raises an error if the document type is not supported" do
      expect {
        described_class.document_type_weighting("manual", "wrong")
      }.to raise_error(KeyError)
    end

    context "with a parent document type" do
      it "returns the weight for a given document type" do
        expect(
          described_class.document_type_weighting("html_publication", "html_publication", parent_document_type: "guidance"),
        ).to eq(1.1)
      end

      it "raises an error if the parent document type is not supported" do
        expect {
          described_class.document_type_weighting("html_publication", "html_publication", parent_document_type: "wrong")
        }.to raise_error(KeyError)
      end
    end
  end

  describe ".call" do
    let(:chunked_content_results) do
      [
        build_chunked_content_result(score: 0.25, schema_name: "publication", document_type: "form"),
        build_chunked_content_result(score: 0.25, schema_name: "guide", document_type: "guide"),
        build_chunked_content_result(score: 0.25, schema_name: "specialist_document", document_type: "export_health_certificate"),
        build_chunked_content_result(score: 0.25, schema_name: "answer", document_type: "answer"),
      ]
    end

    before do
      allow(described_class).to receive(:document_type_weighting)
      allow(described_class).to receive(:document_type_weighting).with("publication", "form").and_return(1.0)
      allow(described_class).to receive(:document_type_weighting).with("guide", "guide").and_return(4.0)
      allow(described_class).to receive(:document_type_weighting).with("specialist_document", "export_health_certificate").and_return(0.8)
      allow(described_class).to receive(:document_type_weighting).with("answer", "answer").and_return(0.0)
      allow(described_class).to receive(:document_type_weighting).with("html_publication", "html_publication", parent_document_type: "form").and_return(1.0)
      allow(described_class).to receive(:document_type_weighting).with("html_publication", "html_publication", parent_document_type: "guide").and_return(4.0)
      allow(described_class).to receive(:document_type_weighting).with("html_publication", "html_publication", parent_document_type: "export_health_certificate").and_return(0.8)
    end

    it "returns an array of Search::ResultsForQuestion::WeightedResult objects" do
      expect(described_class.call(chunked_content_results)).to all(be_a(Search::ResultsForQuestion::WeightedResult))
    end

    it "returns results sorted by weighted_score" do
      expect(described_class.call(chunked_content_results).map { |r| [r.document_type, r.weighted_score] }).to eq(
        [
          ["guide", 1.0], # weighting of 4.0
          ["form", 0.25], # weighting of 1.0
          ["export_health_certificate", 0.2], # weighting of 0.8
          ["answer", 0.0], # weighting of 0.0
        ],
      )
    end

    context "when the parent_document_type is html_publication" do
      let(:chunked_content_results) do
        [
          build_chunked_content_result(score: 0.25, schema_name: "html_publication", document_type: "html_publication", parent_document_type: "form"),
          build_chunked_content_result(score: 0.25, schema_name: "html_publication", document_type: "html_publication", parent_document_type: "guide"),
          build_chunked_content_result(score: 0.25, schema_name: "html_publication", document_type: "html_publication", parent_document_type: "export_health_certificate"),
        ]
      end

      it "returns results sorted based on parent_document_type" do
        expect(described_class.call(chunked_content_results).map { |r| [r.parent_document_type, r.weighted_score] }).to eq(
          [
            ["guide", 1.0], # weighting of 4.0
            ["form", 0.25], # weighting of 1.0
            ["export_health_certificate", 0.2], # weighting of 0.8
          ],
        )
      end
    end
  end

  def build_chunked_content_result(attributes)
    defaults = build(:chunked_content_record).except(:titan_embedding)
    Search::ChunkedContentRepository::Result.new(**defaults.merge(attributes))
  end
end
