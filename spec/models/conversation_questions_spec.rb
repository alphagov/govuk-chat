RSpec.describe ConversationQuestions do
  describe ".to_json" do
    it "returns all attributes as JSON" do
      obj = described_class.new(
        questions: [build(:question)],
      )
      expected_json = {
        questions: obj.questions,
      }.to_json

      expect(obj.to_json).to eq(expected_json)
    end
  end
end
