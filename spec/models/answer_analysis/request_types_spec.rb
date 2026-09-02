RSpec.describe AnswerAnalysis::RequestTypes do
  include_examples "llm calls recordable" do
    let(:model) { build(:answer_analysis_request_types) }
  end

  it_behaves_like "exportable by start and end date" do
    let(:conversation) { create(:conversation) }
    let(:question) { create(:question, conversation:) }
    let(:answer) { create(:answer, question:) }
    let(:create_record_lambda) { ->(time) { create(:answer_analysis_request_types, created_at: time) } }
  end

  describe "#serialize for export" do
    it "returns a request type serialized as json" do
      request_types = create(:answer_analysis_request_types)
      expect(request_types.serialize_for_export).to eq(request_types.as_json)
    end

    it "converts the llm_responses to unparsed JSON" do
      llm_responses = { "some" => "response" }
      request_types = create(:answer_analysis_request_types, llm_responses:)
      expected_response = request_types.as_json.merge("llm_responses" => llm_responses.to_json)
      expect(request_types.serialize_for_export).to eq(expected_response)
    end
  end
end
