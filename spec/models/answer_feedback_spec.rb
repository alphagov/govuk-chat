RSpec.describe AnswerFeedback do
  describe ".exportable" do
    let!(:new_answer_feedback) { create(:answer_feedback, created_at: 2.days.ago) }
    let!(:old_answer_feedback) { create(:answer_feedback, created_at: 4.days.ago - 20.seconds) }

    context "when new answer feedback has been created since the last export" do
      it "returns answer feedback created since the last export time" do
        last_export = 4.days.ago
        current_time = Time.current

        exportable_answer_feedback = described_class.exportable(last_export, current_time)

        expect(exportable_answer_feedback).to include(new_answer_feedback)
        expect(exportable_answer_feedback).not_to include(old_answer_feedback)
      end
    end

    context "when no new answer feedback has been created since the last export" do
      it "does not return any answer feedback" do
        last_export = 1.day.ago
        current_time = Time.current

        exportable_answer_feedback = described_class.exportable(last_export, current_time)

        expect(exportable_answer_feedback.size).to eq(0)
      end
    end
  end

  describe "#serialize for export" do
    it "returns answer_feedback serliazed as json" do
      answer_feedback = create(:answer_feedback)
      expect(answer_feedback.serialize_for_export).to eq(answer_feedback.as_json)
    end
  end
end
