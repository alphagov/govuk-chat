RSpec.describe Bigquery::Uploader do
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
    let!(:answer) { create(:answer, :with_sources, created_at: 2.days.ago) }
    let(:question) { answer.question }
    let(:tempfile) { Tempfile.new }

    before { allow(Google::Cloud::Bigquery).to receive(:new).and_return(bigquery) }

    it "configures the load_job appropriately" do
      config = instance_double(Google::Cloud::Bigquery::LoadJob::Updater,
                               "autodetect=": nil,
                               "format=": nil,
                               "schema_update_options=": nil)
      allow(dataset).to receive(:load_job).and_yield(config).and_return(load_job)

      described_class.call("questions", tempfile)

      expect(config).to have_received(:autodetect=).with(true)
      expect(config).to have_received(:format=).with("json")
      expect(config).to have_received(:schema_update_options=).with(%w[ALLOW_FIELD_ADDITION ALLOW_FIELD_RELAXATION])
    end

    it "uploads the tempfile to bigquery" do
      described_class.call("questions", tempfile)
      expect(dataset).to have_received(:load_job).with("questions", tempfile)
    end

    context "when a table for the table_id doesn't exist in bigquery" do
      let(:schema) { instance_double(Google::Cloud::Bigquery::Schema, timestamp: nil) }

      before do
        allow(dataset).to receive(:create_table).and_yield(table)
        allow(dataset).to receive(:table).and_return(nil)
        allow(table).to receive(:schema).and_yield(schema)
      end

      it "creates the table" do
        described_class.call("questions", tempfile)
        expect(dataset).to have_received(:create_table).with("questions")
      end

      it "configures the table" do
        described_class.call("questions", tempfile)

        expect(schema).to have_received(:timestamp).with("created_at", { mode: :required })
        expect(table).to have_received(:time_partitioning_type=).with("DAY")
        expect(table).to have_received(:time_partitioning_field=).with("created_at")
        expect(table).to have_received(:time_partitioning_expiration=).with(1.year.to_i)
      end

      context "and a 'time_partitioning_field' is provided" do
        it "configures the table and schema with the provided 'time_partitioning_field'" do
          schema = instance_double(Google::Cloud::Bigquery::Schema, timestamp: nil)
          allow(table).to receive(:schema).and_yield(schema)

          described_class.call("questions", tempfile, time_partitioning_field: "exported_until")

          expect(schema).to have_received(:timestamp).with("exported_until", { mode: :required })
          expect(table).to have_received(:time_partitioning_field=).with("exported_until")
        end
      end
    end

    context "when the upload fails" do
      error_message = "Something went wrong"

      before do
        allow(load_job).to receive_messages(error: error_message, failed?: true)
      end

      it "raises an UploadFailedError" do
        expect { described_class.call("questions", tempfile) }
          .to raise_error(Bigquery::Uploader::UploadFailedError, "BigQuery upload failed: Something went wrong")
      end
    end
  end
end
