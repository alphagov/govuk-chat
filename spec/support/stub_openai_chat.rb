module StubOpenAIChat
  def stub_openai_chat_completion(chat_history, answer, chat_options: {}, tool_calls: [])
    stub_request(:post, "https://api.openai.com/v1/chat/completions")
      .with(
        headers: StubOpenAIChat.headers,
        body: StubOpenAIChat.request_body(chat_history, chat_options:),
      )
      .to_return_json(
        status: 200,
        body: StubOpenAIChat.response_body(answer, tool_calls:),
        headers: {},
      )
  end

  def stub_openai_chat_completion_structured_response(chat_history, answer, chat_options: {})
    output_schema = Rails.configuration.llm_prompts.openai_structured_answer[:output_schema]

    structured_generation_chat_options = chat_options.merge(
      {
        model: AnswerComposition::Pipeline::OpenAIStructuredAnswerComposer::OPENAI_MODEL,
        tools: [
          {
            type: "function",
            function: {
              "name": "generate_answer_using_retrieved_contexts",
              "description": "Use the provided contexts to generate an answer to the question.",
              "parameters": {
                "type": output_schema[:type],
                "properties": output_schema[:properties],
              },
              "required": output_schema[:required],
            },
          },
        ],
        tool_choice: "required",
      },
    )

    tool_calls = [
      {
        id: "call_#{SecureRandom.hex(12)}",
        type: "function",
        function: {
          name: "generate_answer_using_retrieved_contexts",
          arguments: answer,
        },
      },
    ]

    stub_openai_chat_completion(chat_history, nil, chat_options: structured_generation_chat_options, tool_calls:)
  end

  def stub_openai_chat_completion_error(status: 400, type: "invalid_request_error", code: nil)
    stub_request(:post, "https://api.openai.com/v1/chat/completions")
      .with(
        headers: StubOpenAIChat.headers,
      )
      .to_return_json(
        status:,
        body: {
          error: {
            message: "Error message",
            type:,
            param: nil,
            code:,
          },
        },
        headers: {},
      )
  end

  def stub_openai_output_guardrail_pass(answer)
    stub_openai_chat_completion(
      array_including({ "role" => "user", "content" => Regexp.new(answer) }),
      "False | None",
      chat_options: { model: OutputGuardrails::FewShot::OPENAI_MODEL,
                      max_tokens: OutputGuardrails::FewShot::OPENAI_MAX_TOKENS },
    )
  end

  def self.response_body(answer, tool_calls:)
    {
      id: "chatcmpl-abc123",
      object: "chat.completion",
      created: 1_677_858_242,
      model: "gpt-3.5-turbo-0613",
      usage: {
        prompt_tokens: 13,
        completion_tokens: 7,
        total_tokens: 20,
      },
      choices: [
        {
          message: {
            role: "assistant",
            content: answer,
            tool_calls:,
          },
          logprobs: nil,
          finish_reason: "stop",
          index: 0,
        },
      ],
    }
  end

  def self.headers
    {
      "Content-Type" => "application/json",
      "Authorization" => "Bearer #{Rails.configuration.openai_access_token}",
    }
  end

  def self.request_body(messages, chat_options:)
    {
      model: "gpt-3.5-turbo",
      messages:,
      temperature: 0.0,
    }.merge(chat_options)
  end
end
