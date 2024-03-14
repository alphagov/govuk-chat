RSpec.describe Question do
  describe "#unanswered" do
    it "returns all questions without an answer" do
      question = create(:question)
      create(:question, :with_answer)

      expect(described_class.unanswered).to eq [question]
    end
  end
end
