RSpec.describe Api::RequestValidationError do
  describe "#render" do
    it "returns an array which uses the GenericErrorBlueprint for the error body" do
      request = double
      error_message = "Bad request"
      generic_error_blueprint = GenericErrorBlueprint.render(message: error_message)

      error = described_class.new(400, :bad_request, error_message, request)
      expect(error.render).to eq([400, { "Content-Type" => "application/json" }, [generic_error_blueprint]])
    end
  end
end
