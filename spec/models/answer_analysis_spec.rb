RSpec.describe AnswerAnalysis do
  include_examples "llm calls recordable" do
    let(:model) { build(:answer_analysis) }
  end

  describe ".exportable" do
    let!(:new_answer_analysis) { create(:answer_analysis, created_at: 2.days.ago) }

    before { create(:answer_analysis, created_at: 4.days.ago) }

    it "returns answer_analyses created since the last export time" do
      last_export = 3.days.ago
      current_time = Time.current

      exportable_answer_analysis = described_class.exportable(last_export, current_time)

      expect(exportable_answer_analysis).to eq([new_answer_analysis])
    end

    it "returns an empty array if there are no new answer topics" do
      last_export = 1.day.ago
      current_time = Time.current

      exportable_answer_analysis = described_class.exportable(last_export, current_time)

      expect(exportable_answer_analysis).to eq([])
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
