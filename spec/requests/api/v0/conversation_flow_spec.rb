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

  describe "API user paginates through a long conversation" do
    let(:conversation) { create(:conversation, :api, signon_user: api_user) }

    before do
      allow(Rails.configuration.conversations).to receive(:api_questions_per_page).and_return(2)
      5.times { create(:question, :with_answer, conversation:) }
    end

    it "allows user to paginate through the conversation" do
      # when_i_request_the_first_page_of_questions
      get api_v0_conversation_questions_path(conversation), as: :json

      # then_i_receive_the_first_page_of_questions
      expect(response).to have_http_status(:ok)

      # when_i_request_the_second_page_of_questions
      earlier_questions_url = JSON.parse(response.body)["earlier_questions_url"]
      get earlier_questions_url

      # then_i_receive_the_second_page_of_questions
      expect(response).to have_http_status(:ok)

      # when_i_request_the_third_page_of_questions
      earlier_questions_url = JSON.parse(response.body)["earlier_questions_url"]
      get earlier_questions_url

      # then_i_receive_the_even_earlier_page_of_questions
      expect(response).to have_http_status(:ok)

      # when_i_request_the_second_page_of_questions
      later_questions_url = JSON.parse(response.body)["later_questions_url"]
      get later_questions_url

      # then_i_receive_the_later_page_of_questions
      expect(response).to have_http_status(:ok)

      # when_i_request_the_first_page_of_questions
      later_questions_url = JSON.parse(response.body)["later_questions_url"]
      get later_questions_url

      # then_i_receive_the_first_page_of_questions
      expect(response).to have_http_status(:ok)
    end
  end
end
