module ExportableModelExamples
  shared_examples "exportable by start and end date" do
    let(:current_time) { Time.current }

    it "returns records created since the last export time" do
      last_export = new_record.created_at - 1.second

      exportable_records = described_class.exportable(last_export, current_time)

      expect(exportable_records).to include(new_record)
      expect(exportable_records).not_to include(old_record)
    end

    it "returns an empty array if no records have been created since the last export" do
      last_export = new_record.created_at + 1.second
      exportable_records = described_class.exportable(last_export, current_time)

      expect(exportable_records).to eq([])
    end
  end
end
