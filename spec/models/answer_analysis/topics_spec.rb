RSpec.describe AnswerAnalysis::Topics do
  include_examples "llm calls recordable" do
    let(:model) { build(:answer_analysis_topics) }
  end

  it_behaves_like "exportable by start and end date" do
    let(:conversation) { create(:conversation, end_user_id: "opted-out-id") }
    let(:question) { create(:question, conversation:) }
    let(:answer) { create(:answer, question:) }
    let(:create_record_lambda) { ->(time) { create(:answer_analysis_topics, created_at: time) } }
    let(:create_excluded_record_lambda) { ->(time) { create(:answer_analysis_topics, answer:, created_at: time) } }

    before { allow(Rails.configuration.govuk_chat_private).to receive(:opted_out_end_user_ids).and_return(%w[opted-out-id]) }
  end

  describe "#serialize for export" do
    it "returns a topic serialized as json" do
      topics = create(:answer_analysis_topics)
      expected_result = topics.as_json.merge("llm_responses" => "null")
      expect(topics.serialize_for_export).to eq(expected_result)
    end

    it "converts the llm_responses to unparsed JSON" do
      llm_responses = { "some" => "response" }
      topics = create(:answer_analysis_topics, llm_responses:)
      expected_response = topics.as_json.merge("llm_responses" => llm_responses.to_json)
      expect(topics.serialize_for_export).to eq(expected_response)
    end
  end
end
