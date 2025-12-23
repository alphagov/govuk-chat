RSpec.describe Bigquery::Exporter do
  describe ".call" do
    before do
      allow(Bigquery::IndividualExport).to receive(:call) do
        Bigquery::IndividualExport::Result.new(tempfile: Tempfile.new, count: 1)
      end

      allow(Bigquery::Uploader).to receive(:call)
    end

    it "returns a result object" do
      freeze_time do
        tables = Bigquery::TABLES_TO_EXPORT.map { |table| [table.name, 1] }.to_h

        expect(described_class.call)
          .to have_attributes(exported_from: instance_of(ActiveSupport::TimeWithZone),
                              exported_until: Time.current,
                              tables:)
      end
    end

    it "exports and uploads data for all Bigquery::TABLES_TO_EXPORT" do
      described_class.call

      tables_count = Bigquery::TABLES_TO_EXPORT.count

      expect(Bigquery::IndividualExport)
        .to have_received(:call).exactly(tables_count).times

      expect(Bigquery::Uploader)
        .to have_received(:call).exactly(tables_count).times
    end

    it "calls Bigquery::IndividualExport and Bigquery::Uploader with the expected arguments for a table" do
      freeze_time do
        first_table = Bigquery::TABLES_TO_EXPORT.first

        described_class.call

        expect(Bigquery::IndividualExport)
          .to have_received(:call).with(first_table.model,
                                        export_from: instance_of(ActiveSupport::TimeWithZone),
                                        export_until: Time.current)

        expect(Bigquery::Uploader)
          .to have_received(:call).with(first_table.name,
                                        instance_of(Tempfile),
                                        { time_partitioning_field: first_table.time_partitioning_field })
      end
    end

    context "when there has been an export previously" do
      let!(:previous_export) { create(:bigquery_export, exported_until: 1.hour.ago, created_at: 1.hour.ago) }

      it "exports data from the time of that export until the current time" do
        freeze_time do
          result = described_class.call

          expect(result).to have_attributes(exported_from: previous_export.exported_until,
                                            exported_until: Time.current)

          expect(Bigquery::IndividualExport)
            .to have_received(:call)
            .with(anything, export_from: previous_export.exported_until, export_until: Time.current)
            .at_least(:once)
        end
      end

      it "creates a BigqueryExport model for the current time" do
        freeze_time do
          expect { described_class.call }.to change(BigqueryExport, :count).by(1)

          expect(BigqueryExport.last.exported_until).to eq(Time.current)
        end
      end
    end

    context "when there hasn't been an export previously" do
      before { BigqueryExport.delete_all }

      it "exports data from the 1st January 2024 until the current time" do
        freeze_time do
          result = described_class.call

          expect(result).to have_attributes(exported_from: Time.zone.local(2024, 1, 1),
                                            exported_until: Time.current)

          expect(Bigquery::IndividualExport)
            .to have_received(:call)
            .with(anything, export_from: Time.zone.local(2024, 1, 1), export_until: Time.current)
            .at_least(:once)
        end
      end

      it "creates two Bigquery export models" do
        expect { described_class.call }.to change(BigqueryExport, :count).by(2)
      end
    end

    context "when a table doesn't have data" do
      before do
        allow(Bigquery::IndividualExport)
          .to receive(:call)
          .with(table_model, export_from: anything, export_until: anything) do
            Bigquery::IndividualExport::Result.new(tempfile: nil, count: 0)
          end
      end

      let(:table_model) { Bigquery::TABLES_TO_EXPORT.first.model }

      it "does not call the uploader for that table" do
        described_class.call

        expect(Bigquery::Uploader).not_to have_received(:call).with(table_model, anything, anything)
      end

      it "returns a count of 0 in the table results" do
        result = described_class.call

        table_name = Bigquery::TABLES_TO_EXPORT.first.name
        expect(result.tables[table_name]).to eq(0)
      end
    end
  end
end
