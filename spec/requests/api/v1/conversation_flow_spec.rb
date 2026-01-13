## These tests are designed to test E2E intercations with the the conversation API.
## While they are requests specs and use the interface provided by request specs
## we have chosen to use the system spec conventions for the tests.
## Tests in this file should follow system spec conventions such as the given/when/then
## syntax, instance variables over lets, and given over before blocks. This will help
## the tests more readable and better express the intent of the tests since they each
## cover multiple requests.

# rubocop:disable RSpec/NoExpectationExample, RSpec/InstanceVariable
RSpec.describe "Conversation API flow" do
  describe "API user conducts a conversation" do
    it "allows user to interact with the conversation API E2E" do
      given_i_am_a_signed_in_api_user
      and_i_have_the_required_headers_set
      when_i_create_a_conversation
      and_i_poll_for_an_answer
      then_i_see_the_question_has_been_accepted

      when_the_question_is_answered
      and_i_poll_for_an_answer
      then_i_receive_that_answer

      when_i_add_another_question_to_the_conversation
      and_i_poll_for_an_answer
      then_i_see_the_question_has_been_accepted

      when_i_attempt_to_submit_another_question_again
      then_i_receive_an_unprocessable_content_response

      when_the_question_is_answered
      and_i_poll_for_an_answer
      then_i_receive_that_answer
    end
  end

  describe "API user paginates through a long conversation" do
    it "allows user to paginate through the conversation" do
      given_i_am_a_signed_in_api_user
      and_i_have_the_required_headers_set
      and_i_have_a_conversation_with_many_questions
      when_i_make_a_request_for_the_conversation
      then_i_receive_a_successful_response

      when_i_request_the_earlier_page_of_questions
      then_i_receive_a_successful_response

      when_i_request_the_earlier_page_of_questions
      then_i_receive_a_successful_response
      and_there_is_no_earlier_questions_url

      when_i_request_the_later_page_of_questions
      then_i_receive_a_successful_response

      when_i_request_the_later_page_of_questions
      then_i_receive_a_successful_response
      and_there_is_no_later_questions_url
    end
  end

  def given_i_am_a_signed_in_api_user
    @api_user = create(:signon_user, :conversation_api)
    login_as(@api_user)
  end

  def and_i_have_the_required_headers_set
    @headers = { "HTTP_GOVUK_CHAT_END_USER_ID" => "end-user-123" }
  end

  def when_i_create_a_conversation
    allow(AnswerComposition::Composer).to receive(:call) do |question|
      question.build_answer(
        message: "Stubbed answer for #{question.message}",
        status: :answered,
      )
    end
    allow(AnswerAnalysis::TagTopicsJob).to receive(:perform_later)
    allow(AnswerAnalysis::AnswerRelevancyJob).to receive(:perform_later)
    allow(AnswerAnalysis::CoherenceJob).to receive(:perform_later)
    allow(AnswerAnalysis::FaithfulnessJob).to receive(:perform_later)

    post api_v1_create_conversation_path,
         params: { user_question: "What is the capital of France?" },
         headers: @headers,
         as: :json
    @conversation_id = JSON.parse(response.body)["conversation_id"]
    @answer_url = JSON.parse(response.body)["answer_url"]
  end

  def and_i_poll_for_an_answer
    get(@answer_url, headers: @headers)
  end

  def then_i_see_the_question_has_been_accepted
    expect(response).to have_http_status(:accepted)
  end

  def when_the_question_is_answered
    execute_queued_sidekiq_jobs
  end

  def then_i_receive_that_answer
    expect(response).to have_http_status(:ok)
  end
  alias_method :then_i_receive_a_successful_response, :then_i_receive_that_answer

  def when_i_add_another_question_to_the_conversation
    put api_v1_update_conversation_path(@conversation_id),
        params: { user_question: "What is the capital of Spain?" },
        headers: @headers,
        as: :json
    @answer_url = JSON.parse(response.body)["answer_url"]
  end

  def when_i_attempt_to_submit_another_question_again
    put api_v1_update_conversation_path(@conversation_id),
        params: { user_question: "What is the capital of Spain?" },
        headers: @headers,
        as: :json
  end

  def then_i_receive_an_unprocessable_content_response
    expect(response).to have_http_status(:unprocessable_content)
  end

  def and_i_have_a_conversation_with_many_questions
    @conversation = create(
      :conversation,
      :api,
      signon_user: @api_user,
      end_user_id: "end-user-123",
    )
    5.times { create(:question, :with_answer, conversation: @conversation) }
  end

  def when_i_make_a_request_for_the_conversation
    allow(Rails.configuration.conversations).to receive(:api_questions_per_page).and_return(2)
    get(api_v1_show_conversation_path(@conversation), headers: @headers)
  end

  def when_i_request_the_earlier_page_of_questions
    get(JSON.parse(response.body)["earlier_questions_url"], headers: @headers)
  end
  alias_method :when_i_request_the_earliest_page_of_questions, :when_i_request_the_earlier_page_of_questions

  def and_there_is_no_earlier_questions_url
    expect(JSON.parse(response.body)["earlier_questions_url"]).to be_nil
  end

  def when_i_request_the_later_page_of_questions
    get(JSON.parse(response.body)["later_questions_url"], headers: @headers)
  end

  def and_there_is_no_later_questions_url
    expect(JSON.parse(response.body)["later_questions_url"]).to be_nil
  end
end
# rubocop:enable RSpec/NoExpectationExample, RSpec/InstanceVariable
