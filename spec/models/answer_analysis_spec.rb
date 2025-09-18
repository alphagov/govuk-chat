RSpec.describe AnswerAnalysis do
  include_examples "llm calls recordable" do
    let(:model) { build(:answer_analysis) }
  end

  it_behaves_like "exportable by start and end date" do
    let(:conversation) { create(:conversation, end_user_id: "opted-out-id") }
    let(:question) { create(:question, conversation:) }
    let(:answer) { create(:answer, question:) }
    let(:create_record_lambda) { ->(time) { create(:answer_analysis, created_at: time) } }
    let(:create_excluded_record_lambda) { ->(time) { create(:answer_analysis, answer:, created_at: time) } }

    before { allow(Rails.configuration.govuk_chat_private).to receive(:opted_out_end_user_ids).and_return(%w[opted-out-id]) }
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
