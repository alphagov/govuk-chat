RSpec.describe BedrockConverseClient do
  describe ".converse" do
    let(:user_message) { "Hello, this is a user message." }
    let(:bedrock_client) { Aws::BedrockRuntime::Client.new(stub_responses: true) }

    it "calls the Bedrock Converse API with the correct parameters" do
      allow(Aws::BedrockRuntime::Client).to receive(:new).and_return(bedrock_client)
      allow(bedrock_client).to receive(:converse)
      stub_bedrock_converse(
        bedrock_converse_client_response(
          content: { "response" => "This is the first text content block." }.to_json,
        ),
      )

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
  end

  describe ".parse_first_text_content_from_response" do
    it "extracts and parses the first text content block from the response" do
      bedrock_response = Aws::BedrockRuntime::Types::ConverseResponse.new(
        output: Aws::BedrockRuntime::Types::ConverseOutput.new(
          message: Aws::BedrockRuntime::Types::Message.new(
            content: [
              Aws::BedrockRuntime::Types::ContentBlock::ReasoningContent.new(
                reasoning_content: "Reasoning for text output.",
              ),
              Aws::BedrockRuntime::Types::ContentBlock::Text.new(
                text: { "key" => "value" }.to_json,
              ),
              Aws::BedrockRuntime::Types::ContentBlock::Text.new(
                text: { "another_key" => "another_value" }.to_json,
              ),
            ],
          ),
        ),
      )

      parsed_content = described_class.parse_first_text_content_from_response(bedrock_response)

      expect(parsed_content).to eq({ "key" => "value" })
    end
  end
end
