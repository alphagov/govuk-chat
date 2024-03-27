RSpec.describe Form::ConfirmUnderstandRisk do
  describe "validations" do
    it "is valid when confirmation is present" do
      form = described_class.new(confirmation: "understand_risk")
      expect(form).to be_valid
    end

    it "is invalid when confirmation is not present" do
      form = described_class.new
      form.validate

      expect(form.errors.messages[:confirmation])
        .to eq(["Check the checkbox to show you understand the guidance"])
    end
  end
end
