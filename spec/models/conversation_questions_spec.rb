RSpec.describe ConversationQuestions do
  describe ".to_json" do
    it "returns all attributes as JSON" do
      obj = described_class.new(
        questions: [build(:question)],
        earlier_questions_url: "/earlier",
        later_questions_url: "/later",
      )
      expected_json = {
        questions: obj.questions,
        earlier_questions_url: "/earlier",
        later_questions_url: "/later",
      }.to_json

      expect(obj.to_json).to eq(expected_json)
    end

    it "removes nil attributes from JSON" do
      obj = described_class.new(
        questions: [build(:question)],
        earlier_questions_url: nil,
        later_questions_url: "/later",
      )
      expected_json = {
        questions: obj.questions,
        later_questions_url: "/later",
      }.to_json

      expect(obj.to_json).to eq(expected_json)
    end
  end
end
