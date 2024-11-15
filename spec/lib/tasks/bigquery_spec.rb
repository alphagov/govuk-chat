RSpec.describe "rake bigquery tasks" do
  let(:bigquery) { instance_double(Google::Cloud::Bigquery::Project, dataset: bigquery_dataset) }
  let(:bigquery_dataset) do
    instance_double(Google::Cloud::Bigquery::Dataset,
                    table: bigquery_table,
                    load_job: bigquery_load_job)
  end

  let(:bigquery_load_job) do
    instance_double(Google::Cloud::Bigquery::LoadJob,
                    wait_until_done!: nil,
                    failed?: false)
  end
  let(:bigquery_table) { instance_double(Google::Cloud::Bigquery::Table) }

  before do
    allow(Google::Cloud::Bigquery).to receive(:new).and_return(bigquery)
    allow(bigquery_table).to receive(:delete)
  end

  describe "bigquery:export" do
    let(:task_name) { "bigquery:export" }

    before do
      Rake::Task[task_name].reenable
      stub_request(:get, /api.smartsurvey.io/)
        .to_return_json(status: 200, body: { responses: 1 })
    end

    it "prints what it has exported" do
      previous_export = create(:bigquery_export)

      tables_output = Bigquery::TABLES_TO_EXPORT.map do |table|
        count = table.name =~ /(smart_survey_responses|aggregates)$/ ? 1 : 0
        "Table #{table.name} (#{count})\n"
      end

      freeze_time do
        expected = "Records exported from #{previous_export.exported_until} to " \
          "#{Time.current}:\n#{tables_output.join}"

        expect { Rake::Task[task_name].invoke }.to output(expected).to_stdout
      end
    end

    it "delegates to Bigquery::Exporter" do
      expect(Bigquery::Exporter).to receive(:call).and_call_original

      expect { Rake::Task[task_name].invoke }.to output.to_stdout
    end
  end

  describe "bigquery:delete_table" do
    let(:task_name) { "bigquery:delete_table" }

    before { Rake::Task[task_name].reenable }

    context "when a table exists in BigQuery" do
      before do
        allow(bigquery_dataset).to receive(:table).with("my_table").and_return(bigquery_table)
      end

      it "deletes the table" do
        expected_output = "Deleted my_table table from BigQuery\n"

        expect { Rake::Task[task_name].invoke("my_table") }
          .to output(expected_output).to_stdout

        expect(bigquery_table).to have_received(:delete)
      end
    end

    context "when a table doesn't exist in BigQuery" do
      before do
        allow(bigquery_dataset).to receive(:table).with("my_table").and_return(nil)
      end

      it "exits with an error" do
        expect { Rake::Task[task_name].invoke("my_table") }
          .to raise_error(SystemExit)
          .and output("BigQuery table doesn't exist: my_table\n").to_stderr

        expect(bigquery_table).not_to have_received(:delete)
      end
    end
  end

  describe "bigquery:reset" do
    let(:task_name) { "bigquery:reset" }

    before { Rake::Task[task_name].reenable }

    it "deletes big query tables for each table in Bigquery::TABLES_TO_EXPORT" do
      table_names = Bigquery::TABLES_TO_EXPORT.map(&:name)

      expected_output = "Deleted tables: #{table_names.join(', ')}"
      expect { Rake::Task[task_name].invoke }
        .to output(/#{expected_output}/).to_stdout

      expect(bigquery_table)
        .to have_received(:delete).exactly(Bigquery::TABLES_TO_EXPORT.count).times
    end

    it "deletes all BigqueryExport records" do
      create_list(:bigquery_export, 3)

      expect { Rake::Task[task_name].invoke }
        .to output(/Deleted all #{BigqueryExport.count} BigqueryExport records/).to_stdout
        .and change(BigqueryExport, :count).to(0)
    end
  end
end
