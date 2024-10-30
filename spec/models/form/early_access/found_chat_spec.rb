RSpec.describe Form::EarlyAccess::FoundChat do
  describe "validations" do
    it "is valid with a choice" do
      form = described_class.new(choice: "search_engine")
      expect(form).to be_valid
    end

    it "is invalid without a choice" do
      form = described_class.new(choice: "")
      expect(form).to be_invalid
      expect(form.errors.messages[:choice])
        .to eq([described_class::CHOICE_PRESENCE_ERROR_MESSAGE])
    end
  end
end
