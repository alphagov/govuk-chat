RSpec.describe GenericErrorBlueprint do
  describe ".render_as_json" do
    it "renders the correct JSON based on the message passed in" do
      expect(described_class.render_as_json(message: "test-message"))
        .to eq({ message: "test-message" }.as_json)
    end
  end
end
