RSpec.describe Bigquery::Resetter do
  describe ".call" do
    let(:bigquery) { instance_double(Google::Cloud::Bigquery::Project, dataset:) }
    let(:dataset) { instance_double(Google::Cloud::Bigquery::Dataset, table:) }
    let(:table) { instance_double(Google::Cloud::Bigquery::Table) }

    before do
      allow(Google::Cloud::Bigquery).to receive(:new).and_return(bigquery)
      allow(table).to receive(:delete)
    end

    context "when there are existing exports" do
      it "deletes all BigqueryExport records" do
        create(:bigquery_export)
        expect { described_class.call }.to change(BigqueryExport, :count).to(0)
      end

      it "deletes all tables in bigquery" do
        described_class.call
        Bigquery::TOP_LEVEL_MODELS_TO_EXPORT.each do |model|
          table_name = model.table_name

          expect(dataset).to have_received(:table).with(table_name)
          expect(dataset.table(table_name))
            .to have_received(:delete)
            .exactly(Bigquery::TOP_LEVEL_MODELS_TO_EXPORT.size).times
        end
      end
    end
  end
end
