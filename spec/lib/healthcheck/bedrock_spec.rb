RSpec.describe Healthcheck::Bedrock do
  include StubBedrock

  let(:healthcheck) { described_class.new }

  describe "#name" do
    it "returns ':bedrock'" do
      expect(described_class.new.name).to eq(:bedrock)
    end
  end

  describe "#status" do
    context "when the invoke_model endpoint is available" do
      it "returns GovukHealthcheck::OK" do
        stub_bedrock_invoke_model(
          { content_type: "application/json", body: {}.to_json },
        )
        expect(healthcheck.status).to eq(GovukHealthcheck::OK)
      end
    end

    context "when an error is thrown" do
      before do
        bedrock_client = Aws::BedrockRuntime::Client.new(stub_responses: true)
        allow(Aws::BedrockRuntime::Client).to receive(:new).and_return(bedrock_client)
        allow(bedrock_client).to receive(:invoke_model).and_raise(StandardError.new("Contrived error"))
      end

      it "returns GovukHealthcheck::CRITICAL" do
        expect(healthcheck.status).to eq(GovukHealthcheck::CRITICAL)
      end

      it "sets the message attribute to the error message" do
        healthcheck.status
        expect(healthcheck.message).to eq("Contrived error")
      end
    end
  end
end
