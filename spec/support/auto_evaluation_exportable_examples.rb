shared_examples "auto evaluation exportable runs" do
  let(:run_factory_name) { described_class.name.demodulize.underscore }

  describe "#serialize_for_export" do
    it "returns a serialized object for export" do
      record = build(
        run_factory_name,
        llm_responses: {
          "verdicts" => { "verdicts" => [{ "verdict" => "yes" }] },
          "reason" => { "reason" => "This is the reason for the score." },
        },
      )

      expected = record.as_json.merge(
        "llm_responses" => record.llm_responses.to_json,
      )
      expect(record.serialize_for_export).to eq(expected)
    end
  end
end
