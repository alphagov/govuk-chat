RSpec.describe AutoEvaluation::BedrockOpenAIOssInvoke, :aws_credentials_stubbed do #  rubocop:disable RSpec/SpecFilePathFormat
  describe ".call" do
    let(:user_message) { "Hello, this is a user message." }
    let(:tool) do
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
      }
    end
    let!(:stub) do
      stub_bedrock_invoke_model_openai_oss_tool_call(
        user_message,
        tool,
        { "response" => "Expected response." }.to_json,
      )
    end

    it "returns a Result object with the evaluation data" do
      result = described_class.call(user_message:, tool:)

      expect(result).to be_a(described_class::Result)
      expect(result.evaluation_data).to eq({ "response" => "Expected response." })
    end

    it "records the llm response on the result" do
      result = described_class.call(user_message:, tool:)
      expect(result.llm_response).to eq(JSON.parse(stub.response.body))
    end

    it "records the metrics on the result" do
      allow(Clock).to receive(:monotonic_time).and_return(100.0, 101.0)

      result = described_class.call(user_message:, tool:)

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
        tool,
        { "invalid_key" => "This does not conform to the schema." }.to_json,
      )

      expect {
        described_class.call(user_message:, tool:)
      }.to raise_error(
        described_class::InvalidToolCallError,
        /The property '#\/' did not contain a required property of 'response'/,
      )
    end

    it "raises an error if the response exceeds the maximum token count" do
      stub_bedrock_invoke_model_openai_oss_tool_call(
        user_message,
        tool,
        nil,
        finish_reason: "length",
      )

      expect {
        described_class.call(user_message:, tool:)
      }.to raise_error(described_class::LengthLimitExceededError)
    end

    context "when cached tokens are included in the response" do
      let!(:stub) do
        stub_bedrock_invoke_model_openai_oss_tool_call(
          user_message,
          tool,
          { "response" => "Expected response." }.to_json,
          usage: {
            completion_tokens: 35,
            prompt_tokens: 25,
            prompt_tokens_details: { cached_tokens: 10, total_tokens: 60 },
          },
        )
      end

      it "records the cached tokens in the metrics" do
        result = described_class.call(user_message:, tool:)
        expect(result.metrics[:llm_cached_tokens]).to eq(10)
      end
    end

    context "when a system prompt is provided" do
      let(:system_prompt) { "This is a system prompt." }
      let!(:stub) do
        stub_bedrock_invoke_model_openai_oss_tool_call(
          user_message,
          tool,
          { "response" => "Expected response." }.to_json,
          system_prompt:,
        )
      end

      it "includes the system prompt in the messages sent to Bedrock" do
        described_class.call(user_message:, tool:, system_prompt:)

        expect(stub).to have_been_requested
      end
    end

    context "when the llm returns invalid JSON" do
      it "raises an InvalidToolCallError" do
        stub_bedrock_invoke_model_openai_oss_tool_call(
          user_message,
          tool,
          "invalid_json",
        )

        expected_error_message = "LLM did not return valid JSON that conformed to the schema. Error: unexpected character: 'invalid_json'"

        expect { described_class.call(user_message:, tool:) }.to raise_error(
          described_class::InvalidToolCallError,
          /#{expected_error_message}/,
        )
      end
    end

    context "when the llm returns JSON that does not conform to the schema" do
      it "raises an InvalidToolCallError" do
        stub_bedrock_invoke_model_openai_oss_tool_call(
          user_message,
          tool,
          { "invalid_key" => "This does not conform to the schema." }.to_json,
        )

        expected_error_message = /The property '#\/' did not contain a required property of 'response'/

        expect { described_class.call(user_message:, tool:) }.to raise_error(
          described_class::InvalidToolCallError,
          /#{expected_error_message}/,
        )
      end
    end

    context "when the llm response does not include a tool call" do
      it "raises an InvalidToolCallError" do
        body = {
          choices: [
            content: "This is a response without a tool call.",
            finish_reason: "stop",
          ],
        }
        stub_request(:post, StubBedrock::OPENAI_GPT_OSS_ENDPOINT_REGEX)
                .to_return_json(
                  status: 200,
                  body: body.to_json,
                  headers: { "Content-Type" => "application/json" },
                )

        expect { described_class.call(user_message:, tool:) }.to raise_error(
          described_class::InvalidToolCallError,
          "No tool call arguments returned in the LLM response",
        )
      end
    end
  end
end
