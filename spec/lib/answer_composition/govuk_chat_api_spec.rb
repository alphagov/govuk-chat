RSpec.describe AnswerComposition::GovukChatApi do
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
    let(:sources_list) { %w[https://gov.uk/taxes https://gov.uk/vat https://gov.uk/income-tax] }

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
        status: "success",
        persisted?: false,
      )
      expect(answer.sources.map(&:path)).to match_array(["/taxes", "/vat", "/income-tax"])
    end
  end
end
