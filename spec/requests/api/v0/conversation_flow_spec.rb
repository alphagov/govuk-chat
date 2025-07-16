RSpec.describe "Conversation API flow" do
  let(:api_user) { create(:signon_user, :conversation_api) }

  before { login_as(api_user) }

  describe "API user conducts a conversation" do
    before do
      allow(AnswerComposition::Composer).to receive(:call) do |question|
        question.build_answer(
          message: "Stubbed answer for #{question.message}",
          status: :answered,
        )
      end
    end

    it "allows user to interact with the conversation API E2E" do
      # when_i_create_a_conversation
      post api_v0_create_conversation_path,
           params: { user_question: "What is the captial of France" },
           as: :json
      expect(response).to have_http_status(:created)

      # and_i_poll_for_an_answer
      execute_queued_sidekiq_jobs
      answer_url = JSON.parse(response.body)["answer_url"]
      get answer_url

      # then_i_receive_that_answer
      expect(response).to have_http_status(:ok)

      # when_i_add_another_question_to_the_conversation
      question = Question.last
      put api_v0_update_conversation_path(question.conversation_id),
          params: { user_question: "What is the capital of Spain?" },
          as: :json
      expect(response).to have_http_status(:created)

      # and_i_poll_for_an_answer
      execute_queued_sidekiq_jobs
      answer_url = JSON.parse(response.body)["answer_url"]
      get answer_url

      # then_i_receive_that_answer
      expect(response).to have_http_status(:ok)
    end
  end
end
