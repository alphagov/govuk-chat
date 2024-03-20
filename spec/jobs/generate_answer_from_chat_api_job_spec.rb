RSpec.describe GenerateAnswerFromChatApiJob do
  include ActiveJob::TestHelper

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

  describe "#perform" do
    it "stores the answer and sources returned from the chat api" do
      sources_list = %w[https://example.com https://example.org]
      chat_api_response = {
        answer: "Hello, how can I help you?",
        sources: sources_list,
      }.to_json
      stub_chat_api_client(question.conversation_id, user_input, chat_api_response, chat_url)

      expect { described_class.new.perform(question.id) }
        .to change(Answer, :count).by(1)
        .and change(AnswerSource, :count).by(2)

      answer = Answer.last
      expect(answer.message).to eq("Hello, how can I help you?")

      sources = AnswerSource.last(2)
      expect(sources.map(&:url)).to match_array(sources_list)
    end

    it "stores the answer sources in the correct order of relevancy" do
      sources_list = %w[https://example.com https://example2.org https://example3.org]
      chat_api_response = {
        answer: "Hello, how can I help you?",
        sources: sources_list,
      }.to_json
      stub_chat_api_client(question.conversation_id, user_input, chat_api_response, chat_url)

      described_class.new.perform(question.id)

      sources = AnswerSource.last(3)
      expect(sources.map(&:relevancy)).to eq([0, 1, 2])
    end

    context "when the question has already been answered" do
      let(:question) { create(:question, :with_answer) }

      it "logs a warning" do
        expect(described_class.logger)
          .to receive(:warn)
          .with("Question #{question.id} has already been answered")

        expect { described_class.new.perform(question.id) }
          .not_to change(Answer, :count)
      end
    end

    context "when the question does not exist" do
      it "logs a warning" do
        question_id = 999
        expect(described_class.logger)
          .to receive(:warn)
          .with("No question found for #{question_id}")

        expect { described_class.new.perform(question_id) }
          .not_to change(Answer, :count)
      end
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
