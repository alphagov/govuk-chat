RSpec.describe Conversation do
  describe ".without_questions" do
    it "returns all conversations that have no questions" do
      create(:question)
      conversation = create(:conversation)

      expect(described_class.without_questions).to eq [conversation]
    end
  end
end
