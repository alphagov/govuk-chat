RSpec.describe ValidationErrorBlueprint do
  describe ".render_as_json" do
    it "renders the correct JSON based on the errors passed in" do
      errors = {
        user_question: ["Question must be 300 characters or less", "Personal data has been detected in your question. Please remove it and try asking again."],
        base: ["Previous question pending. Please wait for a response"],
      }

      expect(described_class.render_as_json(errors:))
        .to eq({ message: "Unprocessable entity", errors: }.as_json)
    end
  end
end
