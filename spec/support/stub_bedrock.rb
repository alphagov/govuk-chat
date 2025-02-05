module StubBedrock
  # Usage scenarios
  #
  # Stub question message provides specific answer
  #     client = stub_bedrock_converse(
  #       bedrock_claude_structured_answer_response("Expected question", "Expected answer")
  #     )
  #
  # Stub multiple responses
  #     client = stub_bedrock_converse(
  #       bedrock_claude_structured_answer_response("Expected question 1", "Expected answer 1")
  #       bedrock_claude_structured_answer_response("Expected question 2", "Expected answer 2")
  #     )
  #
  # Simulate basic tool response
  #     client = stub_bedrock_converse(
  #       bedrock_claude_tool_response({ "key" => "value" }, tool_name)
  #     )
  #
  # Simulate an error
  #     client = stub_bedrock_converse("NotFound")
  #     client.converse(model_id: "just-generating-an-error")
  #     => Aws::BedrockRuntime::Errors::ServerError: stubbed-response-error-message
  def stub_bedrock_converse(*responses)
    bedrock_client = Aws::BedrockRuntime::Client.new(stub_responses: true)
    allow(Aws::BedrockRuntime::Client).to receive(:new).and_return(bedrock_client)
    bedrock_client.stub_responses(:converse, responses)
    bedrock_client
  end

  def bedrock_claude_structured_answer_response(question, answer)
    lambda do |context|
      given_question = context.params.dig(:messages, -1, :content, 0, :text)

      if question && given_question != question
        raise "Unexpected question received: \"#{given_question}\". Expected \"#{question}\"."
      end

      bedrock_claude_tool_response(
        { "answer" => answer, "confidence" => 0.9 },
        tool_name: "answer_confidence",
      )
    end
  end

  def bedrock_claude_tool_response(tool_input,
                                   tool_name:,
                                   tool_use_id: SecureRandom.hex,
                                   input_tokens: 10,
                                   output_tokens: 20)
    {
      output: {
        message: {
          role: "assistant",
          content: [
            {
              tool_use: {
                input: tool_input,
                tool_use_id:,
                name: tool_name,
              },
            },
          ],
        },
      },
      stop_reason: "end_turn",
      usage: {
        input_tokens:,
        output_tokens:,
        total_tokens: input_tokens + output_tokens,
      },
      metrics: {
        latency_ms: 999,
      },
    }
  end
end
