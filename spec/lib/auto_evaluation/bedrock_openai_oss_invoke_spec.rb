RSpec.describe AutoEvaluation::BedrockOpenAIOssInvoke, :aws_credentials_stubbed do #  rubocop:disable RSpec/SpecFilePathFormat
  describe ".call" do
    let(:user_message) { "Hello, this is a user message." }
    let(:tools) do
      [
        {
          "type" => "function",
          "function" => {
            "name" => "test_schema",
            "description" => "A test JSON schema",
            "parameters" => {
              "type" => "object",
              "properties" => {
                "response" => { "type" => "string" },
              },
              "required" => %w[response],
            },
            "strict" => true,
          },
        },
      ]
    end
    let!(:stub) do
      stub_bedrock_invoke_model_openai_oss_tool_call(
        user_message,
        tools,
        { "response" => "Expected response." }.to_json,
      )
    end

    it "returns a Result object with the evaluation data" do
      result = described_class.call(user_message, tools)

      expect(result).to be_a(described_class::Result)
      expect(result.evaluation_data).to eq({ "response" => "Expected response." })
    end

    it "records the llm response on the result" do
      result = described_class.call(user_message, tools)
      expect(result.llm_response).to eq(JSON.parse(stub.response.body))
    end

    it "records the metrics on the result" do
      allow(Clock).to receive(:monotonic_time).and_return(100.0, 101.0)

      result = described_class.call(user_message, tools)

      expect(result.metrics).to eq(
        {
          duration: 1.0,
          llm_prompt_tokens: 25,
          llm_completion_tokens: 35,
          llm_cached_tokens: nil,
          model: described_class::MODEL,
        },
      )
    end

    it "raises an error if the response does not conform to the schema" do
      stub_bedrock_invoke_model_openai_oss_tool_call(
        user_message,
        tools,
        { "invalid_key" => "This does not conform to the schema." }.to_json,
      )

      expect {
        described_class.call(user_message, tools)
      }.to raise_error(
        described_class::InvalidToolCallSchemaError,
        /The property '#\/' did not contain a required property of 'response'/,
      )
    end

    it "raises an error if the response exceeds the maximum token count" do
      stub_bedrock_invoke_model_openai_oss_tool_call(
        user_message,
        tools,
        nil,
        "length",
      )

      expect {
        described_class.call(user_message, tools)
      }.to raise_error(described_class::LengthLimitExceededError)
    end
  end
end
