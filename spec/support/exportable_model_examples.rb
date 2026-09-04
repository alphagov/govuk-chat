module ExportableModelExamples
  shared_examples "exportable by start and end date" do
    let(:last_export) { 2.days.ago }
    before { create_record_lambda.call(last_export - 1.day) }

    it "returns records created since the last export time" do
      new_record = create_record_lambda.call(last_export + 1.day)

      exportable_records = described_class.exportable(last_export, Time.current)

      expect(exportable_records).to eq([new_record])
    end

    it "returns an empty array if no records have been created since the last export" do
      exportable_records = described_class.exportable(last_export, Time.current)

      expect(exportable_records).to eq([])
    end
  end

  shared_examples "serializes llm_responses as unparsed JSON" do
    it "converts the llm_responses to unparsed JSON" do
      llm_responses = { "some" => { "llm" => "response" } }
      record = build(factory_name, llm_responses:)

      expect(record.serialize_for_export)
        .to include("llm_responses" => llm_responses.to_json)
    end
  end
end
