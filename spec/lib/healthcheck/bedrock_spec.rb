RSpec.describe Healthcheck::Bedrock do
  let(:healthcheck) { described_class.new }

  describe "#name" do
    it "returns ':bedrock'" do
      expect(described_class.new.name).to eq(:bedrock)
    end
  end

  describe "#status" do
    before do
      client = Aws::Bedrock::Client.new(stub_responses: {
        list_foundation_models: response,
      })

      allow(Aws::Bedrock::Client).to receive(:new).and_return(client)

      allow(BedrockModels).to receive(:MODEL_IDS).and_return({
        claude_sonnet_4_0: "eu.anthropic.claude-sonnet-4-20250514-v1:0",
        claude_sonnet_4_6: "eu.anthropic.claude-sonnet-4-6",
        claude_haiku_4_5: "eu.anthropic.claude-haiku-4-5-20251001-v1:0",
        titan_embed_v2: "amazon.titan-embed-text-v2:0",
        openai_gpt_oss_120b: "openai.gpt-oss-120b-1:0",
      })
    end

    context "when the models available cover all models used by Chat" do
      let(:response) do
        {
          model_summaries: [
            Aws::Bedrock::Types::FoundationModelSummary.new(
              model_id: "anthropic.claude-sonnet-4-20250514-v1:0",
              model_arn: "arn:claude-sonnet-4",
            ),
            Aws::Bedrock::Types::FoundationModelSummary.new(
              model_id: "anthropic.claude-sonnet-4-6",
              model_arn: "arn:claude-sonnet-4-6",
            ),
            Aws::Bedrock::Types::FoundationModelSummary.new(
              model_id: "anthropic.claude-haiku-4-5-20251001-v1:0",
              model_arn: "arn:claude-haiku-4-5",
            ),
            Aws::Bedrock::Types::FoundationModelSummary.new(
              model_id: "amazon.titan-embed-text-v2:0",
              model_arn: "arn:titan",
            ),
            Aws::Bedrock::Types::FoundationModelSummary.new(
              model_id: "openai.gpt-oss-120b-1:0",
              model_arn: "arn:gpt-oss",
            ),
          ],
        }
      end

      it "returns GovukHealthcheck::OK" do
        expect(healthcheck.status).to eq(GovukHealthcheck::OK)
      end
    end

    context "when chat uses models that aren't available" do
      let(:response) do
        { model_summaries: [] }
      end

      it "returns GovukHealthcheck::CRITICAL" do
        expect(healthcheck.status).to eq(GovukHealthcheck::CRITICAL)
      end

      it "sets the message attribute to show the name of the missing models" do
        healthcheck.status
        expect(healthcheck.message).to eq(
          "Bedrock model(s) not available: amazon.titan-embed-text-v2:0, anthropic.claude-haiku-4-5-20251001-v1:0, " \
          "anthropic.claude-sonnet-4-20250514-v1:0, anthropic.claude-sonnet-4-6, openai.gpt-oss-120b-1:0",
        )
      end
    end

    context "when an error is thrown" do
      let(:response) { RuntimeError.new("Contrived error") }

      it "returns GovukHealthcheck::CRITICAL" do
        expect(healthcheck.status).to eq(GovukHealthcheck::CRITICAL)
      end

      it "sets the message attribute to the error message" do
        healthcheck.status
        expect(healthcheck.message).to eq(
          "Communicating with Bedrock failed with a RuntimeError error",
        )
      end
    end
  end
end
