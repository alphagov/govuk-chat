RSpec.describe Bigquery::Backfiller do
  let(:bigquery) { instance_double(Google::Cloud::Bigquery::Project, dataset: bigquery_dataset) }
  let(:bigquery_dataset) { instance_double(Google::Cloud::Bigquery::Dataset, table: bigquery_table) }
  let(:bigquery_table) { instance_double(Google::Cloud::Bigquery::Table) }

  before do
    allow(Google::Cloud::Bigquery).to receive(:new).and_return(bigquery)
    allow(bigquery_table).to receive(:delete)
  end

  describe ".call" do
    before do
      allow(Bigquery::IndividualExport).to receive(:call) do
        Bigquery::IndividualExport::Result.new(tempfile: Tempfile.new, count: 1)
      end

      allow(Bigquery::Uploader).to receive(:call)
    end

    let(:table) { Bigquery::TABLES_TO_EXPORT.first }

    context "when there has been a previous export" do
      let!(:previous_export) { create(:bigquery_export) }

      it "accepts a table and returns a result object" do
        expect(described_class.call(table))
          .to have_attributes(name: table.name,
                              count: 1,
                              exported_until: previous_export.exported_until)
      end

      it "deletes an existing bigquery table" do
        described_class.call(table)

        expect(bigquery_table).to have_received(:delete)
      end

      it "calls Bigquery::IndividualExport and Bigquery::Uploader with the expected arguments for a table" do
        described_class.call(table)

        expect(Bigquery::IndividualExport)
          .to have_received(:call).with(table.name, export_until: previous_export.exported_until)

        expect(Bigquery::Uploader)
          .to have_received(:call).with(table.name,
                                        instance_of(Tempfile),
                                        { time_partitioning_field: table.time_partitioning_field })
      end

      context "and a table doesn't have any data" do
        before do
          allow(Bigquery::IndividualExport).to receive(:call) do
            Bigquery::IndividualExport::Result.new(tempfile: nil, count: 0)
          end
        end

        it "does not call the uploader" do
          described_class.call(table)

          expect(Bigquery::Uploader).not_to have_received(:call)
        end

        it "returns a count of 0 in the results" do
          result = described_class.call(table)

          expect(result.count).to eq(0)
        end
      end
    end

    context "when there hasn't been an export previously" do
      before { BigqueryExport.delete_all }

      it "raises an error" do
        expect { described_class.call(table) }
          .to raise_error("There are no exports so no need to backfill")
      end
    end
  end
end
