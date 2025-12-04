RSpec.describe BedrockConverseClient do
  describe ".converse" do
    let(:user_message) { "Hello, this is a user message." }
    let(:bedrock_client) { Aws::BedrockRuntime::Client.new(stub_responses: true) }
    let(:bedrock_client_response) do
      bedrock_converse_client_response(
        content: { "response" => "This is the first text content block." }.to_json,
      )
    end

    before do
      allow(Aws::BedrockRuntime::Client).to receive(:new).and_return(bedrock_client)
      allow(bedrock_client).to receive(:converse).and_call_original
      stub_bedrock_converse(bedrock_client_response)
    end

    it "calls the Bedrock Converse API with the correct parameters" do
      described_class.converse(user_message)

      expected_request_args = {
        model_id: BedrockConverseClient::MODEL,
        messages: [{ role: "user", content: [{ text: user_message }] }],
        inference_config: {
          max_tokens: 4096,
          temperature: 0.0,
        },
      }
      expect(bedrock_client).to have_received(:converse).with(expected_request_args)
    end

    it "returns a Result object with the text content and LLM response" do
      result = described_class.converse(user_message)

      expect(result).to be_a(BedrockConverseClient::Result)
      expect(result.text_content).to eq({ "response" => "This is the first text content block." })
      expect(result.llm_response).to eq(bedrock_client_response)
    end

    context "when the llm response contains multiple content blocks" do
      it "parses and returns the first text content block" do
        bedrock_response = Aws::BedrockRuntime::Types::ConverseResponse.new(
          output: Aws::BedrockRuntime::Types::ConverseOutput.new(
            message: Aws::BedrockRuntime::Types::Message.new(
              role: "assistant",
              content: [
                Aws::BedrockRuntime::Types::ContentBlock::ReasoningContent.new(
                  reasoning_content: {
                    reasoning_text: {
                      text: "This is a reasoning content block.",
                    },
                  },
                ),
                Aws::BedrockRuntime::Types::ContentBlock::Text.new(
                  text: { "response" => "This is the first text content block." }.to_json,
                ),
                Aws::BedrockRuntime::Types::ContentBlock::Text.new(
                  text: { "response" => "This is the second text content block." }.to_json,
                ),
              ],
            ),
          ),
          stop_reason: "end_turn",
          usage: Aws::BedrockRuntime::Types::TokenUsage.new(
            input_tokens: 25,
            output_tokens: 35,
            total_tokens: 60,
          ),
          metrics: { latency_ms: 2000 },
        )
        stub_bedrock_converse(bedrock_response)
        result = described_class.converse(user_message)

        expect(result.text_content).to eq({ "response" => "This is the first text content block." })
      end
    end
  end
end
