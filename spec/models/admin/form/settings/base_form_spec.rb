RSpec.describe Admin::Form::Settings::BaseForm do
  describe "validations" do
    it "is invalid when author_comment is more than 255 chars" do
      valid_form = described_class.new(author_comment: "a" * 255)
      invalid_form = described_class.new(author_comment: "a" * 256)

      expect(valid_form).to be_valid
      expect(invalid_form).to be_invalid
      expect(invalid_form.errors.messages[:author_comment])
        .to eq(["Author comment must be 255 characters or less"])
    end
  end
end
