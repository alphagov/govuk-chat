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
    before do
      allow(Rails.configuration).to receive(:smart_survey).and_return(
        Hashie::Mash.new(
          survey_id: "12345",
          api_key: "test_smart_survey_username",
          api_key_secret: "test_smart_survey_password",
        ),
      )
    end

    it "can successfully return a Result for each table_name in Bigquery::TABLES_TO_EXPORT" do
      stub_smart_survey_request

      results = Bigquery::TABLES_TO_EXPORT.map do |table|
        described_class.call(table.name)
      end

      expect(results).to all(be_a(described_class::Result))
    end

    context "when given a table name of 'smart_survey_responses'" do
      it "returns a result with data up to the time of the smart survey request" do
        freeze_time do
          smart_survey_request = stub_smart_survey_request(responses: 10)

          result = described_class.call("smart_survey_responses")

          expect(smart_survey_request).to have_been_made
          expect(result.count).to eq(1)

          tempfile_json = JSON.parse(result.tempfile.read)
          expect(tempfile_json).to match({ "completed_surveys" => 10,
                                           "exported_until" => Time.current })
        end
      end

      it "raises an error if a smart survey request fails" do
        stub_smart_survey_request(status: 500)

        expect { described_class.call("smart_survey_responses") }
          .to raise_error(Faraday::Error)
      end
    end

    context "when given a table name for aggregate statistics" do
      let(:table_name) { "early_access_users_aggregates" }

      it "returns a result with a single record containing the model's `aggregate_export_data` as JSON" do
        export_until = Time.current

        result = described_class.call(table_name, export_until:)

        expect(result.count).to eq(1)

        tempfile_json = JSON.parse(result.tempfile.read)
        expect(tempfile_json).to match(EarlyAccessUser.aggregate_export_data(export_until))
      end
    end

    context "when given a model table name" do
      let(:table_name) { "questions" }
      let(:export_from) { 3.hours.ago }
      let(:export_until) { 1.hour.ago }

      it "returns a result with the count of the items from the timeframe" do
        create_list(:answer, 3, created_at: 2.hours.ago)

        result = described_class.call(table_name, export_from:, export_until:)

        expect(result.count).to eq(3)
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

  def stub_smart_survey_request(status: 200, responses: 1)
    stub_request(:get, "https://api.smartsurvey.io/v1/surveys/12345")
      .with(
        headers: {
          "Accept" => "application/json",
          "Authorization" => "Basic #{Base64.strict_encode64('test_smart_survey_username:test_smart_survey_password').chomp}",
        },
      )
      .to_return_json(status:, body: { responses: })
  end
end
