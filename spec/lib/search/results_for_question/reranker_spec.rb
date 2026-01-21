RSpec.describe Search::ResultsForQuestion::Reranker do
  describe ".call" do
    it "returns the weight for a given document type" do
      result = build_chunked_content_result(score: 0.25, schema_name: "simple_smart_answer", document_type: "simple_smart_answer")

      expect(described_class.call([result]).first.weighting).to eq(2.0)
    end

    it "returns the default weight for a given document type" do
      result = build_chunked_content_result(score: 0.25, schema_name: "manual", document_type: "manual")

      expect(described_class.call([result]).first.weighting).to eq(described_class::DEFAULT_WEIGHTING)
    end

    it "returns the default weight if the document type is not supported" do
      result = build_chunked_content_result(score: 0.25, schema_name: "manual", document_type: "wrong")

      expect(described_class.call([result]).first.weighting).to eq(described_class::DEFAULT_WEIGHTING)
    end

    context "with a parent document type" do
      it "returns the weight for a given document type" do
        result = build_chunked_content_result(score: 0.25, schema_name: "html_publication", document_type: "html_publication", parent_document_type: "guidance")

        expect(described_class.call([result]).first.weighting).to eq(1.1)
      end

      it "returns the default weight if the parent document type is not supported" do
        result = build_chunked_content_result(score: 0.25, schema_name: "html_publication", document_type: "html_publication", parent_document_type: "wrong")

        expect(described_class.call([result]).first.weighting).to eq(described_class::DEFAULT_WEIGHTING)
      end
    end

    context "when schema_name is nil" do
      let(:document_types_by_schema) do
        {
          "first_schema" => { "document_types" => { "guide" => { "weight" => 1.2 } } },
          "second_schema" => { "document_types" => { "guide" => { "weight" => 2.2 } } },
        }
      end

      before do
        allow(Rails.configuration.search).to receive(:document_types_by_schema).and_return(document_types_by_schema)
        allow(Rails.logger).to receive(:warn)
      end

      it "falls back to the first matching schema and warns" do
        result = build_chunked_content_result(score: 0.25, schema_name: nil, document_type: "guide")

        expect(described_class.call([result]).first.weighting).to eq(1.2)

        expect(Rails.logger).to have_received(:warn).with(
          "Search::ResultsForQuestion::Reranker: nil schema_name for document_type=\"guide\"; " \
          "falling back to schema_name=\"first_schema\"",
        )
      end

      it "warns when no matching document type is found" do
        result = build_chunked_content_result(score: 0.25, schema_name: nil, document_type: "missing")

        expect(described_class.call([result]).first.weighting).to eq(described_class::DEFAULT_WEIGHTING)

        expect(Rails.logger).to have_received(:warn).with(
          "Search::ResultsForQuestion::Reranker: nil schema_name for document_type=\"missing\"; " \
          "no matching document type config found",
        )
      end
    end

    context "when schema_name is configured but document_type is missing" do
      before do
        allow(Rails.configuration.search).to receive(:document_types_by_schema).and_return(
          "guide" => { "document_types" => { "other" => { "weight" => 1.3 } } },
        )
        allow(Rails.logger).to receive(:warn)
      end

      it "warns and returns the default weight" do
        result = build_chunked_content_result(score: 0.25, schema_name: "guide", document_type: "guide")

        expect(described_class.call([result]).first.weighting).to eq(described_class::DEFAULT_WEIGHTING)

        expect(Rails.logger).to have_received(:warn).with(
          "Search::ResultsForQuestion::Reranker: no document type config for schema_name=\"guide\" " \
          "document_type=\"guide\"",
        )
      end
    end

    context "when schema_name is not configured" do
      before do
        allow(Rails.configuration.search).to receive(:document_types_by_schema).and_return({})
        allow(Rails.logger).to receive(:warn)
      end

      it "warns and returns the default weight" do
        result = build_chunked_content_result(score: 0.25, schema_name: "missing_schema", document_type: "guide")

        expect(described_class.call([result]).first.weighting).to eq(described_class::DEFAULT_WEIGHTING)

        expect(Rails.logger).to have_received(:warn).with(
          "Search::ResultsForQuestion::Reranker: schema_name=\"missing_schema\" not configured in search.document_types_by_schema",
        )
      end
    end

    context "when document type config exists but is blank" do
      before do
        allow(Rails.configuration.search).to receive(:document_types_by_schema).and_return(
          "publication" => { "document_types" => { "form" => nil } },
        )
      end

      it "does not warn and returns the default weight" do
        expect(Rails.logger).not_to receive(:warn)
        result = build_chunked_content_result(score: 0.25, schema_name: "publication", document_type: "form")

        expect(described_class.call([result]).first.weighting).to eq(described_class::DEFAULT_WEIGHTING)
      end
    end

    context "with multiple results" do
      let(:chunked_content_results) do
        [
          build_chunked_content_result(score: 0.25, schema_name: "publication", document_type: "form"),
          build_chunked_content_result(score: 0.25, schema_name: "guide", document_type: "guide"),
          build_chunked_content_result(score: 0.25, schema_name: "html_publication", document_type: "html_publication", parent_document_type: "guidance"),
        ]
      end

      before do
        allow(Rails.configuration.search).to receive(:document_types_by_schema).and_return(
          "publication" => { "document_types" => { "form" => { "weight" => 1.0 } } },
          "guide" => { "document_types" => { "guide" => { "weight" => 4.0 } } },
          "html_publication" => {
            "document_types" => {
              "html_publication" => {
                "requires_parent_document_type" => {
                  "guidance" => { "weight" => 0.0 },
                },
              },
            },
          },
        )
      end

      it "returns an array of Search::ResultsForQuestion::WeightedResult objects" do
        expect(described_class.call(chunked_content_results)).to all(be_a(Search::ResultsForQuestion::WeightedResult))
      end

      it "returns results sorted by weighted_score" do
        results = described_class.call(chunked_content_results).map do |r|
          [r.document_type, r.weighted_score, r.parent_document_type, r.schema_name]
        end

        expect(results).to eq(
          [
            ["guide", 1.0, nil, "guide"],
            ["form", 0.25, nil, "publication"],
            ["html_publication", 0.0, "guidance", "html_publication"],
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
