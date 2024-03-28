RSpec.describe AnswerGeneration::ChatApiCompletion do
  let(:question) { create(:question, message: user_input) }
  let(:user_input) { "hello" }
  let(:chat_url) { "https://chat-api.example.com" }

  around do |example|
    ClimateControl.modify(
      CHAT_API_URL: chat_url,
      CHAT_API_USERNAME: "username",
      CHAT_API_PASSWORD: "password",
    ) do
      example.run
    end
  end

  describe ".call" do
    let(:sources_list) { %w[https://example.com https://example2.org https://example3.org] }

    it "return unpersisted answer and sources returned from the chat api" do
      chat_api_response = {
        answer: "Hello, how can I help you?",
        sources: sources_list,
      }.to_json
      stub_chat_api_client(question.conversation_id, user_input, chat_api_response, chat_url)

      answer = described_class.call(question)
      expect(answer).to be_a(Answer)
      expect(answer).to have_attributes(
        question:,
        message: "Hello, how can I help you?",
        persisted?: false,
      )
      expect(answer.sources.map { |s| [s.url, s.relevancy, s.persisted?] }).to match_array(
        [
          ["https://example.com", 0, false],
          ["https://example2.org", 1, false],
          ["https://example3.org", 2, false],
        ],
      )
    end
  end

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
