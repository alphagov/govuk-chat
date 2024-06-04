RSpec.describe Reranking::DocumentTypeWeights do
  describe "reranking configuration" do
    it "only contains keys that are valid document types" do
      expect(Rails.configuration.chunked_content_reranking.keys - GovukSchemas::DocumentTypes.valid_document_types).to be_empty
    end
  end

  describe ".call" do
    context "when the weight is in the configuration" do
      it "returns the configured weight" do
        expect(described_class.call("guide")).to eq(2.0)
      end
    end

    context "when the weight is not in the configuration" do
      it "returns 1" do
        expect(described_class.call("manual")).to eq(1.0)
      end
    end
  end
end
