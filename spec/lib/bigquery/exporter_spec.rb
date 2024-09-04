RSpec.describe Bigquery::Exporter do
  describe ".call" do
    let(:bigquery) { instance_double(Google::Cloud::Bigquery::Project, dataset:) }
    let(:dataset) { instance_double(Google::Cloud::Bigquery::Dataset, table:, load_job:) }
    let(:load_job) { instance_double(Google::Cloud::Bigquery::LoadJob, wait_until_done!: nil, failed?: false) }
    let(:schema) { instance_double(Google::Cloud::Bigquery::Schema) }
    let(:table) do
      instance_double(Google::Cloud::Bigquery::Table,
                      schema:,
                      "time_partitioning_type=" => "DAY",
                      "time_partitioning_field=" => "created_at",
                      "time_partitioning_expiration=" => 1.year.to_i)
    end

    before { allow(Google::Cloud::Bigquery).to receive(:new).and_return(bigquery) }

    it "creates a BigQueryExport record" do
      freeze_time do
        expect { described_class.call }
        .to change { BigqueryExport.where(exported_until: Time.current).count }.by(1)
      end
    end

    it "holds a pessimistic lock on the previous BigqueryExport record to prevent concurrent running" do
      last_export = create(:bigquery_export)
      allow(last_export).to receive(:with_lock).and_call_original
      allow(BigqueryExport).to receive(:last).and_return(last_export)

      described_class.call

      expect(last_export).to have_received(:with_lock)
    end

    it "returns a hash of the outcome of the task" do
      freeze_time do
        last_export = create(:bigquery_export, exported_until: 1.day.ago)
        result = described_class.call
        expect(result).to match(hash_including(:tables,
                                               from: last_export.exported_until,
                                               until: Time.current))
      end
    end

    context "when there is new data since the last export" do
      let(:answer) { create(:answer, :with_sources, created_at: 2.days.ago) }
      let!(:question) { answer.question }

      before do
        create(:bigquery_export, exported_until: 3.days.ago)
      end

      it "provides a JSON file with the correct object to the dataset to load in data" do
        described_class.call

        expect(dataset).to have_received(:load_job) do |table_id, file, _config|
          first_json_record = JSON.parse(file.readline.chomp)

          expect(table_id).to eq("questions")
          expect(first_json_record).to match(
            described_class.remove_nil_values(question.serialize_for_export),
          )
        end
      end

      it "exports all relevant data types" do
        create(:answer_feedback, answer:, created_at: 2.days.ago)

        result = described_class.call

        expect(dataset).to have_received(:load_job).with("questions", any_args)
        expect(dataset).to have_received(:load_job).with("answer_feedback", any_args)
        expect(result[:tables]).to match(questions: 1, answer_feedback: 1)
      end

      it "removes nil values" do
        answer.update!(question_routing_confidence_score: nil)

        described_class.call

        expect(dataset).to have_received(:load_job) do |_, file, _config|
          first_json_record = JSON.parse(file.readline.chomp)
          answer_json = first_json_record["answer"]
          expect(answer_json.keys).not_to include("question_routing_confidence_score")
        end
      end

      it "configures the load_job appropriately" do
        config = instance_double(Google::Cloud::Bigquery::LoadJob::Updater,
                                 "autodetect=": nil,
                                 "format=": nil,
                                 "schema_update_options=": nil)
        allow(dataset).to receive(:load_job).and_yield(config).and_return(load_job)

        described_class.call

        expect(config).to have_received(:autodetect=).with(true)
        expect(config).to have_received(:format=).with("json")
        expect(config).to have_received(:schema_update_options=).with(%w[ALLOW_FIELD_ADDITION ALLOW_FIELD_RELAXATION])
      end
    end

    context "when there is no new data since the last export" do
      it "does not call load_job" do
        create(:bigquery_export, exported_until: 1.day.ago)
        create(:answer, created_at: 2.days.ago)

        result = described_class.call

        expect(dataset).not_to have_received(:load_job)
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

    context "when no tables exist in bigquery" do
      before do
        create(:question, :with_answer)
        create(:answer_feedback)
        allow(dataset).to receive(:create_table).and_yield(table)
        allow(dataset).to receive(:table).and_return(nil)
      end

      it "creates the appropriate tables" do
        described_class.call

        expect(dataset).to have_received(:create_table).with("questions")
        expect(dataset).to have_received(:create_table).with("answer_feedback")
      end

      it "configures the created tables appropriately" do
        schema = instance_double(Google::Cloud::Bigquery::Schema, timestamp: nil)
        allow(table).to receive(:schema).and_yield(schema)

        described_class.call

        expect(schema).to have_received(:timestamp).with("created_at", { mode: :required }).exactly(2).times
        expect(table).to have_received(:time_partitioning_type=).with("DAY").exactly(2).times
        expect(table).to have_received(:time_partitioning_field=).with("created_at").exactly(2).times
        expect(table).to have_received(:time_partitioning_expiration=).with(1.year.to_i).exactly(2).times
      end
    end

    context "when the upload fails" do
      error_message = "Something went wrong"

      before do
        allow(load_job).to receive_messages(error: error_message, failed?: true)
      end

      it "raises an UploadFailedError" do
        create(:question, :with_answer)

        expect { described_class.call }
        .to raise_error(Bigquery::Exporter::UploadFailedError,
                        "BigQuery upload failed: Something went wrong")
      end
    end
  end
end
