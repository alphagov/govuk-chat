RSpec.describe AnswerFeedback do
  describe "#serialize for export" do
    it "returns answer_feedback serliazed as json" do
      answer_feedback = create(:answer_feedback)
      expect(answer_feedback.serialize_for_export).to eq(answer_feedback.as_json)
    end
  end
end
