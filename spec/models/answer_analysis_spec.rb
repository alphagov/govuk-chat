RSpec.describe AnswerAnalysis do
  include_examples "llm calls recordable" do
    let(:model) { build(:answer_analysis) }
  end

  describe ".exportable" do
    it_behaves_like "exportable by start and end date" do
      let(:new_record) { create(:answer_analysis, created_at: 2.days.ago) }
      let(:old_record) { create(:answer_analysis, created_at: 4.days.ago) }

      before do
        new_record
        old_record
      end
    end
  end

  describe "#serialize for export" do
    it "returns a source serialzed as json" do
      topic = create(:answer_analysis)
      expected_result = topic.as_json.merge("llm_responses" => "null")
      expect(topic.serialize_for_export).to eq(expected_result)
    end

    it "converts the llm_responses to unparsed JSON" do
      llm_responses = { "key" => "value" }
      answer_analysis = create(:answer_analysis, llm_responses:)
      expected_response = answer_analysis.as_json.merge("llm_responses" => llm_responses.to_json)
      expect(answer_analysis.serialize_for_export).to eq(expected_response)
    end
  end
end
