RSpec.describe Admin::Form::QuestionsFilter do
  describe "#questions" do
    it "orders the questions by the most recently created" do
      question1 = create(:question, created_at: 2.minutes.ago)
      question2 = create(:question, created_at: 1.minute.ago)

      questions = described_class.new.questions

      expect(questions).to eq([question2, question1])
    end

    it "filters the questions by status" do
      question1 = create(:question)
      question2 = create(:answer, status: "success").question

      questions = described_class.new(status: "pending").questions
      expect(questions).to eq([question1])

      questions = described_class.new(status: "success").questions
      expect(questions).to eq([question2])
    end

    it "paginates the questions" do
      questions = create_list(:question, 26)

      questions = described_class.new(page: 1).questions
      expect(questions.count).to eq(25)

      questions = described_class.new(page: 2).questions
      expect(questions.count).to eq(1)
    end

    context "when a conversation is passed in on initilisation" do
      it "scopes the questions to the conversation" do
        question1 = create(:question, created_at: 2.minutes.ago)
        create(:question, created_at: 1.minute.ago)

        questions = described_class.new(conversation: question1.conversation).questions

        expect(questions).to eq([question1])
      end
    end
  end
end
