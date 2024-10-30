RSpec.describe Form::EarlyAccess::ReasonForVisit do
  describe "validations" do
    it "is valid with a choice" do
      form = described_class.new(choice: "find_specific_answer")
      expect(form).to be_valid
    end

    it "is invalid without a choice" do
      form = described_class.new(choice: "")
      expect(form).to be_invalid
      expect(form.errors.messages[:choice]).to eq([described_class::CHOICE_ERROR_MESSAGE])
    end

    it "is invalid with an invalid choice" do
      form = described_class.new(choice: "invalid")
      expect(form).to be_invalid
      expect(form.errors.messages[:choice]).to eq([described_class::CHOICE_ERROR_MESSAGE])
    end
  end
end
