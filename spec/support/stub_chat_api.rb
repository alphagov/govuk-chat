module StubChatApi
  def stub_chat_api_client(chat_id, user_query, response, url)
    stub_request(:post, "#{url}/govchat")
      .with(
        body: { chat_id:, user_query: }.to_json,
        headers: {
          "Content-Type" => "application/json",
          "Accept" => "application/json",
        },
      )
      .to_return(body: response)
  end
end
