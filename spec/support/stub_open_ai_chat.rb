module StubOpenAiChat
  def stub_openai_chat_response(question, answer)
    stub_request(:post, "https://api.openai.com/v1/chat/completions")
      .with(
        headers: {
          "Content-Type" => "application/json",
          "Authorization" => "Bearer #{ENV['OPENAI_ACCESS_TOKEN']}",
        },
        body: {
          model: "gpt-3.5-turbo",
          messages: [{ role: "user", content: question }],
          temperature: 0.0,
        }.to_json,
      )
      .to_return(
        status: 200,
        body: {
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
        }.to_json,
        headers: {},
      )
  end
end
