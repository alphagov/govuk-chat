RSpec.describe AnswerTopic do
  describe ".exportable" do
    let(:new_answer_topic) { create(:answer_topic, created_at: 2.days.ago) }
    let(:old_answer_topic) { create(:answer_topic, created_at: 4.days.ago) }

    before do
      new_answer_topic
      old_answer_topic
    end

    it "returns answer_topics created since the last export time" do
      last_export = 3.days.ago
      current_time = Time.current

      exportable_answer_topics = described_class.exportable(last_export, current_time)

      expect(exportable_answer_topics).to eq([new_answer_topic])
    end

    it "returns an empty array if there are no new answer topics" do
      last_export = 1.day.ago
      current_time = Time.current

      exportable_answer_topics = described_class.exportable(last_export, current_time)

      expect(exportable_answer_topics).to eq([])
    end
  end

  describe "#serialize for export" do
    it "returns a source serialzed as json" do
      topic = create(:answer_topic)
      expect(topic.serialize_for_export).to eq(topic.as_json)
    end
  end
end
