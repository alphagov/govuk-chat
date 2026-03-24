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

    shared_examples "a retryable error" do |error_class, error_message|
      it "raises an #{error_class} after the maximum number of retries" do
        full_error_message = "LLM did not return valid JSON that conformed to the schema " \
                             "after #{described_class::MAX_ATTEMPTS} attempts. " \
                             "Error: #{error_class}, #{error_message}"

        expect { described_class.call(user_message:, tool:) }.to raise_error(
          described_class::InvalidLlmResponseError,
          /#{full_error_message}/,
        )
        expect(stub).to have_been_requested.times(described_class::MAX_ATTEMPTS)
      end

      it "logs a warning each time #{error_class} is raised" do
        logger = instance_double(Logger)
        allow(Rails).to receive(:logger).and_return(logger)
        (1..described_class::MAX_ATTEMPTS).each do |i|
          expected_log_message = "LLM did not return valid JSON that conformed to the schema. " \
                                 "Attempt #{i}/#{described_class::MAX_ATTEMPTS}. " \
                                 "Error: #{error_class}, #{error_message}"
          expect(logger).to receive(:warn)
            .with(/#{expected_log_message}/)
            .ordered
        end

        expect {
          described_class.call(user_message:, tool:)
        }.to raise_error(described_class::InvalidLlmResponseError)
      end

      it "logs additional information when the error message (or class) changes between retries" do
        logger = instance_double(Logger)
        allow(Rails).to receive(:logger).and_return(logger)
        allow(logger).to receive(:warn)

        call_count = 0
        original_response_body = stub.response.body

        stub_request(:post, StubBedrock::OPENAI_GPT_OSS_ENDPOINT_REGEX).to_return do |_request|
          call_count += 1
          if call_count == 1
            { status: 200, headers: { "Content-Type" => "application/json" }, body: original_response_body }
          else
            {
              status: 200,
              headers: { "Content-Type" => "application/json" },
              body: {
                choices: [{
                  message: {
                    tool_calls: [{ function: { arguments: "not_json" } }],
                  },
                  finish_reason: "stop",
                }],
                usage: { prompt_tokens: 10, completion_tokens: 10 },
              }.to_json,
            }
          end
        end

        error = "#{error_class}, #{error_message}"
        expect(logger).to receive(:warn)
          .with(/#{error}/)
          .ordered
        expect(logger).to receive(:warn)
          .with(/This error is different from the previous error: #{error}/)
          .ordered

        expect {
          described_class.call(user_message: user_message, tool: tool)
        }.to raise_error(described_class::InvalidLlmResponseError)
      end
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
      it_behaves_like "a retryable error",
                      JSON::ParserError,
                      "unexpected character: 'invalid_json'" do
        let!(:stub) do
          stub_bedrock_invoke_model_openai_oss_tool_call(
            user_message,
            tool,
            "invalid_json",
          )
        end
      end
    end

    context "when the llm returns JSON that does not conform to the schema" do
      it_behaves_like "a retryable error",
                      JSON::Schema::ValidationError,
                      "The property '#/' did not contain a required property of 'response'" do
        let!(:stub) do
          stub_bedrock_invoke_model_openai_oss_tool_call(
            user_message,
            tool,
            { "invalid_key" => "This does not conform to the schema." }.to_json,
          )
        end
      end
    end

    context "when the llm response does not include a tool call" do
      it_behaves_like "a retryable error",
                      described_class::MissingToolCallArgumentsError,
                      "No tool call arguments returned in the LLM response." do
        let!(:stub) do
          stub_request(:post, StubBedrock::OPENAI_GPT_OSS_ENDPOINT_REGEX)
            .to_return_json(
              status: 200,
              body: {
                choices: [
                  {
                    content: "This is a response without a tool call.",
                    finish_reason: "stop",
                  },
                ],
              }.to_json,
              headers: { "Content-Type" => "application/json" },
            )
        end
      end
    end

    context "when the llm response exceeds the maximum token count" do
      it_behaves_like "a retryable error",
                      described_class::LengthLimitExceededError,
                      "Finish reason: length" do
        let!(:stub) do
          stub_bedrock_invoke_model_openai_oss_tool_call(
            user_message,
            tool,
            nil,
            finish_reason: "length",
          )
        end
      end
    end
  end
end
