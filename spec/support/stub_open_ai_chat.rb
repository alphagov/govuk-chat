module StubOpenAiChat
  def stub_openai_chat_completion(chat_history, answer)
    stub_request(:post, "https://api.openai.com/v1/chat/completions")
      .with(
        headers:,
        body: request_body(chat_history),
      )
      .to_return_json(
        status: 200,
        body: response_body(answer),
        headers: {},
      )
  end

  def stub_any_openai_chat_completion(answer:)
    stub = stub_request(:post, "https://api.openai.com/v1/chat/completions")
      .with(
        headers:,
      )
      .to_return_json(

        status: 200,
        body: response_body(answer),
        headers: {},

      )
    return unless block_given?

    begin
      yield
    ensure
      remove_request_stub(stub)
    end
  end

  def response_body(answer)
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
          },
          logprobs: nil,
          finish_reason: "stop",
          index: 0,
        },
      ],
    }
  end

  def headers
    {
      "Content-Type" => "application/json",
      "Authorization" => "Bearer #{ENV.fetch('OPENAI_ACCESS_TOKEN', 'no-token-given')}",
    }
  end

  def request_body(messages)
    {
      model: "gpt-3.5-turbo",
      messages:,
      temperature: 0.0,
    }.to_json
  end
end
