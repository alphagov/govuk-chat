module StubBedrock
  TITAN_EMBEDDING_ENDPOINT_REGEX = %r{https://bedrock-runtime\..*\.amazonaws\.com/model/.*titan-embed-text.*?/invoke}
  OPENAI_GPT_OSS_ENDPOINT_REGEX = %r{https://bedrock-runtime\..*\.amazonaws\.com/model/openai\.gpt-oss.*?/invoke}

  def stub_bedrock_invoke_model_response(request_body:,
                                         response_body:,
                                         endpoint_regex: TITAN_EMBEDDING_ENDPOINT_REGEX)
    stub_request(:post, endpoint_regex)
      .with(body: request_body)
      .to_return_json(
        status: 200,
        body: response_body,
        headers: { "Content-Type" => "application/json" },
      )
  end

  def stub_bedrock_invoke_model_response_with_error(request_body:, error:)
    stub_request(:post, TITAN_EMBEDDING_ENDPOINT_REGEX)
      .with(body: request_body)
      .to_raise(error)
  end

  def stub_bedrock_titan_invoke_error(input_text, error_message)
    stub_bedrock_invoke_model_response_with_error(
      request_body: { inputText: input_text }.to_json,
      error: Aws::BedrockRuntime::Errors::ValidationException.new({}, error_message),
    )
  end

  def stub_bedrock_titan_embedding(text)
    stub_bedrock_invoke_model_response(
      request_body: { inputText: text }.to_json,
      response_body: bedrock_titan_embedding_response(mock_titan_embedding(text)),
    )
  end

  def bedrock_titan_embedding_response(embedding_array)
    {
      embedding: embedding_array,
    }.to_json
  end

  def mock_titan_embedding(text, dimensions: Search::ChunkedContentRepository::TITAN_EMBEDDING_DIMENSIONS)
    # This returns a mock vector embedding which is deterministic based on the
    # text given
    random_generator = Random.new(text.bytes.sum)
    dimensions.times.map { random_generator.rand }
  end

  def stub_bedrock_invoke_model_openai_oss_tool_call(user_message, tools, content)
    request_body = {
      include_reasoning: false,
      messages: [
        { role: "user", content: [{ type: "text", text: user_message }] },
      ],
      tools:,
      tool_choice: "required",
      parallel_tool_calls: false,
      max_tokens: 4096,
      temperature: 0.0,
    }.to_json

    response_body = {
      choices: [
        {
          message: {
            tool_calls: [
              {
                type: "function",
                function: {
                  arguments: content,
                },
              },
            ],
          },
        },
      ],
      model: "openai.gpt-oss-120b-1:0",
      usage: { completion_tokens: 35, prompt_tokens: 25, total_tokens: 60 },
    }.to_json

    stub_bedrock_invoke_model_response(
      request_body: request_body,
      response_body: response_body,
      endpoint_regex: OPENAI_GPT_OSS_ENDPOINT_REGEX,
    )
  end

  def stub_bedrock_invoke_model_openai_oss_answer_relevancy(question_message:,
                                                            answer_message:,
                                                            statements_json: { statements: ["Statement."] }.to_json,
                                                            verdicts_json: { verdicts: [{ "verdict" => "yes" }] }.to_json,
                                                            reason_json: { reason: "This is the reason for the score." }.to_json)
    prompts = AutoEvaluation::Prompts.config.answer_relevancy

    statements_user_prompt = sprintf(
      prompts.fetch(:statements).fetch(:user_prompt),
      answer: answer_message,
    )
    verdicts_user_prompt = sprintf(
      prompts.fetch(:verdicts).fetch(:user_prompt),
      question: question_message,
      statements: JSON.parse(statements_json).fetch("statements"),
    )
    reason_user_prompt = sprintf(
      prompts.fetch(:reason).fetch(:user_prompt),
      score: 0.5,
      unsuccessful_verdicts_reasons: ["The statement is irrelevant."],
      question: question_message,
    )

    statements_tools = [prompts.fetch(:statements).fetch(:tool_spec)]
    verdicts_tools = [prompts.fetch(:verdicts).fetch(:tool_spec)]
    reason_tools = [prompts.fetch(:reason).fetch(:tool_spec)]

    stubs = {}
    stubs[:statements] = stub_bedrock_invoke_model_openai_oss_tool_call(
      statements_user_prompt,
      statements_tools,
      statements_json,
    )

    stubs[:verdicts] = stub_bedrock_invoke_model_openai_oss_tool_call(
      verdicts_user_prompt,
      verdicts_tools,
      verdicts_json,
    )

    stubs[:reason] = stub_bedrock_invoke_model_openai_oss_tool_call(
      reason_user_prompt,
      reason_tools,
      reason_json,
    )

    stubs
  end
end
