RSpec.describe Search::ResultsForQuestion::ResultSet do
  describe ".empty" do
    it "returns an empty ResultSet" do
      result_set = described_class.empty
      expect(result_set).to be_a(described_class)
      expect(result_set).to have_attributes(
        results: [],
        rejected_results: [],
      )
    end
  end

  describe "#empty?" do
    context "when both results and rejected_results are empty" do
      it "returns true" do
        result_set = described_class.new(results: [], rejected_results: [])
        expect(result_set.empty?).to be(true)
      end
    end

    context "when results is not empty" do
      it "returns false" do
        result_set = described_class.new(results: [{}], rejected_results: [])
        expect(result_set.empty?).to be(false)
      end
    end

    context "when rejected_results is not empty" do
      it "returns false" do
        result_set = described_class.new(results: [], rejected_results: [{}])
        expect(result_set.empty?).to be(false)
      end
    end
  end
end
