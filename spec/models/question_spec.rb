RSpec.describe Question do
  describe ".unanswered" do
    it "returns all questions without an answer" do
      question = create(:question)
      create(:question, :with_answer)

      expect(described_class.unanswered).to eq [question]
    end
  end

  describe ".active" do
    it "returns questions newer than the configured max_question_age" do
      freeze_time do
        allow(Rails.configuration.conversations).to receive(:max_question_age_days).and_return(1)
        to_find = create(:question, created_at: 1.day.ago)
        create(:question, created_at: 1.day.ago - 1.second)
        expect(described_class.active).to eq([to_find])
      end
    end
  end

  describe "#answer_status" do
    it "returns the status of the answer" do
      question = create(:question, :with_answer)
      expect(question.answer_status).to eq "success"
    end

    it "returns 'pending' if the question has no answer" do
      question = create(:question)
      expect(question.answer_status).to eq "pending"
    end
  end
end
