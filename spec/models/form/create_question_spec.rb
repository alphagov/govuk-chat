RSpec.describe Form::CreateQuestion do
  describe "validations" do
    it "is valid when user_question is present and 300 chars of less" do
      form = described_class.new(user_question: SecureRandom.alphanumeric(300))
      expect(form).to be_valid
    end

    it "is invalid when user_question has more than 300 chars" do
      form = described_class.new(user_question: SecureRandom.alphanumeric(301))
      form.validate

      expect(form.errors.messages[:user_question]).to eq(["Question must be 300 characters or less"])
    end

    it "is invalid when user_question is blank" do
      form = described_class.new(user_question: "")
      form.validate

      expect(form.errors.messages[:user_question]).to eq(["Enter a question"])
    end
  end

  describe "#submit" do
    it "creates a conversation and question with the user_question as the message when valid" do
      form = described_class.new(user_question: "How much tax should I be paying?")

      expect { form.submit }.to change(Question, :count).by(1)
      expect(Question.last.message).to eq("How much tax should I be paying?")
    end

    it "raises an error when the form object is invalid" do
      form = described_class.new

      expect { form.submit }.to raise_error(ActiveModel::ValidationError)
    end
  end
end
