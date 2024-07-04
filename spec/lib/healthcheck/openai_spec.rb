RSpec.describe Healthcheck::OpenAI do # rubocop:disable RSpec/SpecFilePathFormat
  include StubOpenAIChat

  let(:healthcheck) { described_class.new }

  describe "#name" do
    it "returns ':openai'" do
      expect(described_class.new.name).to eq(:openai)
    end
  end

  describe "#status" do
    let(:client) { OpenAIClient.build }

    before do
      allow(OpenAIClient).to receive(:build).and_return(client)
    end

    context "when the OpenAI API models endpoint is available" do
      it "returns GovukHealthcheck::OK" do
        stub_openai_models_list
        expect(healthcheck.status).to eq(GovukHealthcheck::OK)
      end
    end

    context "when an error is thrown" do
      before do
        allow(client).to receive(:models).and_raise(OpenAIClient::RequestError, "Contrived error")
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

  def stub_openai_models_list
    stub_request(:get, "https://api.openai.com/v1/models")
      .with(
        headers: StubOpenAIChat.headers,
      )
      .to_return_json(
        status: 200,
      )
  end
end
