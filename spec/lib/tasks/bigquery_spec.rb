RSpec.describe "rake bigquery tasks" do
  let(:bigquery) { instance_double(Google::Cloud::Bigquery::Project, dataset: bigquery_dataset) }
  let(:bigquery_dataset) { instance_double(Google::Cloud::Bigquery::Dataset, table: bigquery_table) }
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

    context "when there is data to export" do
      it "exports the data and prints the output" do
        freeze_time do
          tables_exported = {
            from: Time.current - 1.day,
            until: Time.current,
            tables: {
              questions: 10,
              answer_feedback: 5,
            },
          }
          allow(Bigquery::Exporter).to receive(:call).and_return(tables_exported)

          expected_output = "BigQuery Export: Records exported from #{Time.current - 1.day} to #{Time.current}\nquestions exported: 10\nanswer_feedback exported: 5\n"
          expect { Rake::Task[task_name].invoke }
            .to output(expected_output).to_stdout
          expect(Bigquery::Exporter).to have_received(:call)
        end
      end
    end

    context "when there is no data to export" do
      it "exports the data and prints the output" do
        tables_exported = {
          from: Time.current - 1.day,
          until: Time.current,
          tables: {},
        }
        allow(Bigquery::Exporter).to receive(:call).and_return(tables_exported)

        expect { Rake::Task[task_name].invoke }
          .to output("BigQuery Export: Records exported from #{Time.current - 1.day} to #{Time.current}\n").to_stdout
        expect(Bigquery::Exporter).to have_received(:call)
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
