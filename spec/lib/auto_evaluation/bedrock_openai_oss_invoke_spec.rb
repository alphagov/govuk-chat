RSpec.describe AutoEvaluation::BedrockOpenAIOssInvoke, :aws_credentials_stubbed do #  rubocop:disable RSpec/SpecFilePathFormat
  describe ".call" do
    let(:user_message) { "Hello, this is a user message." }
    let(:json_schema) do
      {
        name: "test_schema",
        description: "A test JSON schema",
        schema: {
          type: "object",
          properties: {
            response: { type: "string" },
          },
          required: %w[response],
        },
        strict: true,
      }
    end

    it "returns a Result object with the text content, LLM response and metrics" do
      stub = bedrock_invoke_model_openai_oss_structured_response(
        user_message,
        json_schema,
        { "response" => "Expected response." }.to_json,
      )
      allow(Clock).to receive(:monotonic_time).and_return(1, 2)
      result = described_class.call(user_message, json_schema)

      expect(result).to be_a(described_class::Result)
      expect(result).to have_attributes(
        evaluation_data: { "response" => "Expected response." },
        llm_response: JSON.parse(stub.response.body),
        metrics: {
          duration: 1,
          llm_prompt_tokens: 25,
          llm_completion_tokens: 35,
          llm_cached_tokens: nil,
          model: described_class::MODEL,
        },
      )
    end

    context "when the structured content starts with an extra curly brace" do
      it "strips it from the json payload" do
        bedrock_invoke_model_openai_oss_structured_response(
          user_message,
          json_schema,
          "{ {\"response\": \"Expected response with additional brace.\"}",
        )
        bedrock_invoke_model_openai_oss_structured_response(
          "Another user message",
          json_schema,
          "{\n{\n\"response\": \"Expected response with additional brace and newlines.\"}",
        )

        result = described_class.call(user_message, json_schema)
        expect(result.evaluation_data)
          .to eq({ "response" => "Expected response with additional brace." })
        result = described_class.call("Another user message", json_schema)
        expect(result.evaluation_data)
          .to eq({ "response" => "Expected response with additional brace and newlines." })
      end
    end
  end
end
