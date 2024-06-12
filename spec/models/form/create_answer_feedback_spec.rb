RSpec.describe Form::CreateAnswerFeedback do
  describe "validations" do
    let(:answer) { build(:answer) }

    it "is valid when 'useful' is present" do
      form = described_class.new(answer:, useful: true)
      expect(form).to be_valid
    end

    it "is invalid when 'useful' is nil" do
      form = described_class.new(answer:)
      expect(form).to be_invalid
      expect(form.errors[:useful]).to eq(["Useful must be true or false"])
    end

    it "is invalid when the answer already has feedback" do
      answer_with_feedback = build(:answer, :with_feedback)
      form = described_class.new(useful: true, answer: answer_with_feedback)
      expect(form).to be_invalid
      expect(form.errors[:answer_feedback]).to eq(["Feedback already provided"])
    end
  end

  describe "#submit" do
    it "raises an error when the form object is invalid" do
      form = described_class.new
      expect { form.submit }.to raise_error(ActiveModel::ValidationError)
    end

    it "creates a new feedback record for the answer" do
      create(:answer)
      answer = Answer.includes(:feedback).last

      described_class.new(answer:, useful: true).submit

      expect(answer.feedback.useful).to eq true
    end
  end
end
