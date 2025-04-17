RSpec.describe ValidationErrorBlueprint do
  describe ".render_as_json" do
    it "renders the correct JSON based on the message and errors passed in" do
      fields = {
        user_question: ["Question must be 300 characters or less", "Personal data has been detected in your question. Please remove it and try asking again."],
        base: ["Previous question pending. Please wait for a response"],
      }

      expect(described_class.render_as_json(message: "test-message", fields:))
        .to eq({ message: "test-message", fields: }.as_json)
    end
  end
end
