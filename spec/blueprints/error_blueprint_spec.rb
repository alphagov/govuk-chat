RSpec.describe ErrorBlueprint do
  describe ".render_as_json" do
    it "generates the correct JSON based on the message passed in" do
      error_message = "An error occurred"
      expect(described_class.render_as_json(message: error_message))
        .to eq({ message: error_message }.as_json)
    end

    it "raises an error when no message is passed in" do
      expect { described_class.render_as_json }.to raise_error(ArgumentError)
    end
  end
end
