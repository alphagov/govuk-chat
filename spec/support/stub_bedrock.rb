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
        { "answer" => answer, "answered" => true, "sources_used" => %w[link_1] },
        tool_name: "output_schema",
      )
    end
  end

  def bedrock_claude_text_response(response_text,
                                   user_message: nil,
                                   input_tokens: 10,
                                   output_tokens: 20)
    lambda do |context|
      if user_message.present?
        included_in_messages = context.params[:messages].any? do |msg|
          if user_message.is_a?(String)
            msg[:role] == "user" && msg[:content].first[:text] == user_message
          elsif user_message.is_a?(Regexp)
            msg[:role] == "user" && msg[:content].first[:text] =~ user_message
          end
        end

        unless included_in_messages
          err = <<~MSG
            Message not found in prompt messages.

            Expected message:
            #{user_message}

            #{ENV['CI'].blank? ? "Prompt messages:\n#{context.params[:messages].inspect}\n" : 'Not shown in CI'}
          MSG
          raise(err)
        end
      end

      bedrock_claude_response({ text: response_text }, input_tokens:, output_tokens:)
    end
  end

  def bedrock_claude_tool_response(tool_input,
                                   tool_name:,
                                   tool_use_id: SecureRandom.hex,
                                   input_tokens: 10,
                                   output_tokens: 20)
    message_content = {
      tool_use: {
        input: tool_input,
        tool_use_id:,
        name: tool_name,
      },
    }

    bedrock_claude_response(message_content, input_tokens:, output_tokens:)
  end

  def bedrock_claude_response(message_content, input_tokens: 10, output_tokens: 20)
    {
      output: {
        message: {
          role: "assistant",
          content: [message_content],
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
