RSpec.describe Form::CreateAnswerFeedback do
  describe "validations" do
    let(:answer) { build(:answer) }

    %w[positive negative].each do |reaction|
      it "is valid when the reaction is '#{reaction}'" do
        form = described_class.new(answer:, reaction:)
        expect(form).to be_valid
      end
    end

    it "is invalid when the reaction is nil" do
      form = described_class.new(answer:)
      expect(form).to be_invalid
      expect(form.errors[:reaction]).to eq([described_class::REACTION_INCLUSION_ERROR_MESSAGE])
    end

    it "is invalid when the reaction is not a recognised value" do
      form = described_class.new(answer:, reaction: "indifferent")
      expect(form).to be_invalid
      expect(form.errors[:reaction]).to eq([described_class::REACTION_INCLUSION_ERROR_MESSAGE])
    end
  end

  describe "#submit" do
    it "raises an error when the form object is invalid" do
      form = described_class.new
      expect { form.submit }.to raise_error(ActiveModel::ValidationError)
    end

    it "creates a feedback record for the answer" do
      create(:answer)
      answer = Answer.includes(:feedback).last

      form = described_class.new(answer:, reaction: "negative")

      expect { form.submit }.to change(AnswerFeedback, :count).by(1)
      expect(answer.reload.feedback.reaction).to eq("negative")
    end

    it "raises when the answer already has feedback" do
      answer = create(:answer)
      create(:answer_feedback, answer:)
      answer = Answer.includes(:feedback).find(answer.id)

      form = described_class.new(answer:, reaction: "negative")

      expect { form.submit }.to raise_error(ActiveRecord::RecordNotUnique)
    end

    it "returns the created feedback" do
      create(:answer)
      answer = Answer.includes(:feedback).last

      feedback = described_class.new(answer:, reaction: "positive").submit

      expect(feedback).to be_a(AnswerFeedback)
      expect(feedback.reaction).to eq("positive")
    end
  end
end
