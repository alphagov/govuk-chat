RSpec.describe Bigquery::Exporter do
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
      allow(Bigquery::Uploader).to receive(:call)
    end

    it "creates a BigQueryExport record" do
      freeze_time do
        expect { described_class.call }
        .to change { BigqueryExport.where(exported_until: Time.current).count }.by(1)
      end
    end

    it "calls Bigquery::Uploader with a model and tempfile with the correct JSON for each aggregate statistics model" do
      freeze_time do
        described_class.call

        expect(Bigquery::Uploader)
          .to have_received(:call).with(
            "early_access_users",
            kind_of(Tempfile),
            time_partitioning_field: "exported_until",
          ) do |_table_id, file, _time_partioning_field|
            json_record = JSON.parse(file.readline.chomp)
            expect(json_record).to match(
              EarlyAccessUser.aggregate_export_data(Time.current),
            )
          end

        expect(Bigquery::Uploader)
          .to have_received(:call).with(
            "waiting_list_users",
            kind_of(Tempfile),
            time_partitioning_field: "exported_until",
          ) do |_table_id, file, _time_partioning_field|
            json_record = JSON.parse(file.readline.chomp)
            expect(json_record).to match(
              WaitingListUser.aggregate_export_data(Time.current),
            )
          end
      end
    end

    it "returns a hash of the outcome of the task" do
      freeze_time do
        last_export = create(:bigquery_export, exported_until: 1.day.ago)
        result = described_class.call
        expect(result)
          .to eq(
            tables: {
              questions: 0,
              answer_feedback: 0,
            },
            from: last_export.exported_until,
            until: Time.current,
          )
      end
    end

    context "when there is new TOP_LEVEL_MODELS_TO_EXPORT data since the last export" do
      let(:answer) { create(:answer, :with_sources, created_at: 2.days.ago) }
      let!(:question) { answer.question }
      let!(:answer_feedback) { create(:answer_feedback, created_at: 2.days.ago) }
      let!(:last_export) { create(:bigquery_export, exported_until: 3.days.ago) }

      it "calls Bigquery::Uploader with a model and tempfile with the correct JSON for each top level model" do
        described_class.call

        expect(Bigquery::Uploader).to have_received(:call).with("questions", kind_of(Tempfile)) do |_table_id, file|
          first_json_record = JSON.parse(file.readline.chomp)
          expect(first_json_record).to match(
            described_class.remove_nil_values(question.serialize_for_export),
          )
        end

        expect(Bigquery::Uploader).to have_received(:call).with("answer_feedback", kind_of(Tempfile)) do |_table_id, file|
          first_json_record = JSON.parse(file.readline.chomp)
          expect(first_json_record).to match(
            described_class.remove_nil_values(answer_feedback.serialize_for_export),
          )
        end
      end

      it "removes nil values fron the serialised records" do
        answer.update!(question_routing_confidence_score: nil)

        described_class.call

        expect(Bigquery::Uploader).to have_received(:call).with("questions", kind_of(Tempfile)) do |_table_id, file|
          first_json_record = JSON.parse(file.readline.chomp)
          answer_json = first_json_record["answer"]
          expect(answer_json.keys).not_to include("question_routing_confidence_score")
        end
      end

      it "increments the top level model counts in the outcome hash" do
        freeze_time do
          result = described_class.call
          expect(result)
            .to eq(
              tables: {
                questions: 1,
                answer_feedback: 1,
              },
              from: last_export.exported_until,
              until: Time.current,
            )
        end
      end
    end

    context "when there is no new data for top level data models since the last export" do
      it "doesn't call Bigquery::Uploader for the top level models" do
        create(:bigquery_export, exported_until: 1.day.ago)
        create(:answer, created_at: 2.days.ago)

        result = described_class.call

        Bigquery::TOP_LEVEL_MODELS_TO_EXPORT.map(&:table_name).each do |table_name|
          expect(Bigquery::Uploader).not_to have_received(:call).with(table_name, any_args)
        end
        expect(result[:tables]).to match(questions: 0, answer_feedback: 0)
      end
    end

    context "when there are no existing bigquery export records" do
      before { BigqueryExport.delete_all }

      it "creates one for 1st of January 2024" do
        freeze_time do
          expect { described_class.call }
          .to change { BigqueryExport.where(exported_until: Time.current).count }.by(1)
        end
      end
    end
  end
end
