RSpec.describe AnswerTopics do
  it_behaves_like "exportable by start and end date" do
    let(:conversation) { create(:conversation, end_user_id: "opted-out-id") }
    let(:question) { create(:question, conversation:) }
    let(:answer) { create(:answer, question:) }
    let(:create_record_lambda) { ->(time) { create(:answer_topics, created_at: time) } }
    let(:create_excluded_record_lambda) { ->(time) { create(:answer_topics, answer:, created_at: time) } }

    before { allow(Rails.configuration.govuk_chat_private).to receive(:opted_out_end_user_ids).and_return(%w[opted-out-id]) }
  end

  describe "#serialize for export" do
    it "returns a topic serialized as json" do
      topic = create(:answer_topics)
      expected_result = topic.as_json.merge("llm_response" => "null")
      expect(topic.serialize_for_export).to eq(expected_result)
    end

    it "converts the llm_responses to unparsed JSON" do
      llm_response = { "some" => "response" }
      answer_topics = create(:answer_topics, llm_response:)
      expected_response = answer_topics.as_json.merge("llm_response" => llm_response.to_json)
      expect(answer_topics.serialize_for_export).to eq(expected_response)
    end
  end
end
