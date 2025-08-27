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
    end

    it "prints what it has exported" do
      previous_export = create(:bigquery_export, exported_until: 2.hours.ago)
      create(:answer, created_at: 1.hour.ago)
      create(:answer_feedback, created_at: 1.hour.ago)
      create(:answer_analysis, created_at: 1.hour.ago)

      expected_counts = {
        "questions" => 1,
        "answer_feedback" => 1,
        "answer_analysis" => 1,
      }

      tables_output = Bigquery::TABLES_TO_EXPORT.map do |table|
        count = expected_counts[table.name]
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

  describe "bigquery:backfill_table" do
    let(:task_name) { "bigquery:backfill_table" }

    before do
      Rake::Task[task_name].reenable
      # We need evidence of past exports to do a backfill
      create(:bigquery_export)
    end

    context "when given a table name that we export to" do
      let(:table) { Bigquery::TABLES_TO_EXPORT.first }

      it "prints what it has exported" do
        expected = "Exported 0 records for table #{table.name}\n"

        expect { Rake::Task[task_name].invoke(table.name) }
          .to output(expected).to_stdout
      end

      it "delegates to Bigquery::Backfiller" do
        expect(Bigquery::Backfiller).to receive(:call).with(table).and_call_original

        expect { Rake::Task[task_name].invoke(table.name) }.to output.to_stdout
      end
    end

    context "when given a table name that we don't know" do
      it "exits with an error" do
        expect(Bigquery::Backfiller).not_to receive(:call)

        expect { Rake::Task[task_name].invoke("my_table") }
          .to raise_error(SystemExit)
          .and output("Table my_table is not a table we export to\n").to_stderr
      end
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
