RSpec.describe "rake bigquery_export tasks" do
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

  describe "bigquery:reset" do
    let(:task_name) { "bigquery:reset" }

    before do
      Rake::Task[task_name].reenable
      allow(Bigquery::Resetter).to receive(:call)
    end

    it "runs successfully and prints to stdout" do
      expect { Rake::Task[task_name].invoke }.to output("BigQuery Export: reset\n").to_stdout
      expect(Bigquery::Resetter).to have_received(:call)
    end
  end
end
