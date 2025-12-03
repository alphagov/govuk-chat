RSpec.describe BedrockConverseClient do
  describe ".converse" do
    let(:messages) do
      [
        { role: "user", content: [{ text: "Hello, this is a system prompt." }] },
      ]
    end
    let(:bedrock_client) { Aws::BedrockRuntime::Client.new(stub_responses: true) }

    before do
      allow(Aws::BedrockRuntime::Client).to receive(:new).and_return(bedrock_client)
      allow(bedrock_client).to receive(:converse)
      stub_bedrock_converse(
        bedrock_converse_client_response(
          content: { "response" => "This is the first text content block." }.to_json,
        ),
      )
    end

    it "calls the Bedrock Converse API with the correct parameters" do
      described_class.converse(messages: messages)

      expected_request_args = {
        model_id: BedrockConverseClient::MODEL,
        messages:,
        inference_config: {
          max_tokens: 4096,
          temperature: 0.0,
        },
      }

      expect(bedrock_client).to have_received(:converse).with(expected_request_args)
    end

    it "calls the Bedrock Converse API with the correct parameters when options are provided" do
      options = { inference_config: { max_tokens: 100, temperature: 0.5 } }
      described_class.converse(messages: messages, options:)

      expected_request_args = {
        model_id: BedrockConverseClient::MODEL,
        messages:,
        inference_config: options[:inference_config],
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
