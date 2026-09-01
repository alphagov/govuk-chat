RSpec.describe AnswerFeedback do
  it_behaves_like "exportable by start and end date" do
    let(:conversation) { create(:conversation) }
    let(:question) { create(:question, conversation:) }
    let(:answer) { create(:answer, question:) }
    let(:create_record_lambda) { ->(time) { create(:answer_feedback, created_at: time) } }
  end

  describe "#serialize_for_export" do
    it "returns the answer feedback serialized as json" do
      answer_feedback = create(:answer_feedback)

      expect(answer_feedback.serialize_for_export).to eq(answer_feedback.as_json)
    end
  end
end
