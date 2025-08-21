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

  describe "#enabled?" do
    context "when the answer strategy is 'openai_structured_answer'" do
      before do
        allow(Rails.configuration).to receive(:answer_strategy).and_return("openai_structured_answer")
      end

      it "returns true" do
        expect(healthcheck.enabled?).to be true
      end
    end

    context "when the answer strategy is not 'openai_structured_answer'" do
      before do
        allow(Rails.configuration).to receive(:answer_strategy).and_return("claude_structured_answer")
      end

      it "returns false" do
        expect(healthcheck.enabled?).to be false
      end
    end
  end

  def stub_openai_models_list
    stub_request(:get, "https://api.openai.com/v1/models")
      .to_return_json(
        status: 200,
        body: {
          "object" => "list",
        },
      )
  end
end
