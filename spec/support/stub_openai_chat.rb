module StubOpenAIChat
  def stub_openai_chat_completion(chat_history, answer)
    stub_request(:post, "https://api.openai.com/v1/chat/completions")
      .with(
        headers: StubOpenAIChat.headers,
        body: StubOpenAIChat.request_body(chat_history),
      )
      .to_return_json(
        status: 200,
        body: StubOpenAIChat.response_body(answer),
        headers: {},
      )
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

  def self.response_body(answer)
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

  def self.headers
    {
      "Content-Type" => "application/json",
      "Authorization" => "Bearer #{Rails.configuration.openai_access_token}",
    }
  end

  def self.request_body(messages)
    {
      model: "gpt-3.5-turbo",
      messages:,
      temperature: 0.0,
    }
  end
end
