RSpec.describe Bigquery::IndividualExport do
  describe ".remove_nil_values" do
    it "removes nil values from nested arrays and hashes" do
      result = described_class.remove_nil_values({
        "a" => {
          "aa" => [1, 2],
          "ab" => {
            "aba" => "a",
            "abb" => nil,
          },
          "ac" => nil,
        },
        "b" => [
          "ba",
          ["bb", nil],
          { "bc" => %w[a], "bd" => nil },
        ],
      })

      expect(result).to eq({
        "a" => {
          "aa" => [1, 2],
          "ab" => { "aba" => "a" },
        },
        "b" => ["ba", %w[bb], { "bc" => %w[a] }],
      })
    end

    it "removes empty arrays and empty hashes" do
      result = described_class.remove_nil_values({
        "a" => {
          "aa" => [nil],
          "ab" => {
            "aba" => nil,
          },
          "ac" => "a",
        },
        "b" => [
          "ba",
          [nil],
          { "bb" => %w[a], "bc" => [nil] },
        ],
      })

      expect(result).to eq({
        "a" => { "ac" => "a" },
        "b" => ["ba", { "bb" => %w[a] }],
      })
    end
  end

  describe ".call" do
    it "can successfully return a Result for each table_name in Bigquery::TABLES_TO_EXPORT" do
      results = Bigquery::TABLES_TO_EXPORT.map do |table|
        described_class.call(table.name)
      end

      expect(results).to all(be_a(described_class::Result))
    end

    context "when given a model table name" do
      let(:table_name) { "questions" }
      let(:export_from) { 3.hours.ago }
      let(:export_until) { 1.hour.ago }

      it "returns a result with the count of the items from the timeframe" do
        create_list(:answer, 3, created_at: 2.hours.ago)
        create(:answer, :with_sources, created_at: 2.hours.ago)

        result = described_class.call(table_name, export_from:, export_until:)

        expect(result.count).to eq(4)
      end

      it "has a tempfile containing JSON of the models serialized for export with nil values removed" do
        # export timestamp is based on when answer is generated, hence easier to
        # create an answer and look up the question than a question with an
        # answer at a specific time.
        question = create(:answer, :with_sources, :with_feedback, created_at: 2.hours.ago).question

        result = described_class.call(table_name, export_from:, export_until:)

        first_json_record = JSON.parse(result.tempfile.readline.chomp)
        expected_json = described_class.remove_nil_values(question.serialize_for_export)

        expect(first_json_record).to match(expected_json)
      end
    end
  end
end
