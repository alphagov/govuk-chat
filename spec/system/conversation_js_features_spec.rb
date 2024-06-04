RSpec.describe "Conversation JavaScript features", :chunked_content_index, :js do
  include ActiveJob::TestHelper

  scenario "questions with answers" do
    given_i_have_confirmed_i_understand_chat_risks
    when_i_visit_the_conversation_page
    and_i_enter_a_first_question
    then_i_see_the_first_question_was_accepted

    when_the_first_answer_is_generated
    then_i_can_see_the_first_answer

    when_i_enter_a_second_question
    then_i_see_the_second_question_was_accepted

    when_the_second_answer_is_generated
    then_i_can_see_the_second_answer
  end

  scenario "client side validation" do
    given_i_have_confirmed_i_understand_chat_risks
    when_i_visit_the_conversation_page
    and_i_enter_an_empty_question
    then_i_see_a_presence_validation_message

    when_i_enter_a_valid_question
    then_i_see_the_valid_question_was_accepted
  end

  scenario "server side validation" do
    given_i_have_confirmed_i_understand_chat_risks
    when_i_visit_the_conversation_page
    and_i_enter_a_question_with_pii
    then_i_see_a_pii_validation_message

    when_i_enter_a_valid_question
    then_i_see_the_valid_question_was_accepted
  end

  scenario "reloading the page while an answer is pending" do
    given_i_have_confirmed_i_understand_chat_risks
    when_i_visit_the_conversation_page
    and_i_enter_a_first_question
    then_i_see_the_first_question_was_accepted

    when_i_reload_the_page
    and_the_first_answer_is_generated
    then_i_can_see_the_first_answer
  end

  def when_i_visit_the_conversation_page
    visit show_conversation_path
  end

  def and_i_enter_a_first_question
    @first_question = "How do I setup a workplace pension?"
    fill_in "create_question[user_question]", with: @first_question
    click_on "Send"
  end
  alias_method :when_i_enter_a_valid_question, :and_i_enter_a_first_question

  def then_i_see_the_first_question_was_accepted
    within(:css, ".js-conversation-list") do
      expect(page).to have_content(@first_question)
    end
  end
  alias_method :then_i_see_the_valid_question_was_accepted, :then_i_see_the_first_question_was_accepted

  def when_the_first_answer_is_generated
    @first_answer = "You can use a simple service on GOV.UK"
    stubs_for_mock_answer(@first_question, @first_answer)

    perform_enqueued_jobs
  end
  alias_method :and_the_first_answer_is_generated, :when_the_first_answer_is_generated

  def then_i_can_see_the_first_answer
    within(:css, ".js-conversation-list") do
      expect(page).to have_content(@first_answer)
    end
  end

  def when_i_enter_a_second_question
    @second_question = "Sounds good, what's the name of the service?"
    fill_in "create_question[user_question]", with: @second_question
    click_on "Send"
  end

  def then_i_see_the_second_question_was_accepted
    within(:css, ".js-conversation-list") do
      expect(page).to have_content(@second_question)
    end
  end

  def when_the_second_answer_is_generated
    @second_answer = "The simple workplace pension service"
    stubs_for_mock_answer(@second_question, @second_answer, rephrase_question: true)

    perform_enqueued_jobs
  end

  def then_i_can_see_the_second_answer
    within(:css, ".js-conversation-list") do
      expect(page).to have_content(@second_answer)
    end
  end

  def and_i_enter_an_empty_question
    fill_in "create_question[user_question]", with: ""
    click_on "Send"
  end

  def then_i_see_a_presence_validation_message
    within(:css, ".js-conversation-form") do
      expect(page).to have_content("Enter a question")
    end
  end

  def and_i_enter_a_question_with_pii
    fill_in "create_question[user_question]", with: "My phone number is 07123456789"
    click_on "Send"
  end

  def then_i_see_a_pii_validation_message
    within(:css, ".js-conversation-form") do
      expect(page).to have_content(/Personal data has been detected/)
    end
  end

  def when_i_reload_the_page
    refresh
  end

  def stubs_for_mock_answer(question, answer, rephrase_question: false)
    if rephrase_question
      rephrased_question = "Rephrased #{question}"

      stub_openai_chat_completion(
        array_including({ "role" => "user", "content" => question }),
        rephrased_question,
      )

      question = rephrased_question
    end

    stub_openai_embedding(question)

    populate_chunked_content_index([
      build(:chunked_content_record, openai_embedding: mock_openai_embedding(question)),
    ])

    stub_openai_chat_completion(
      array_including({ "role" => "user", "content" => question }),
      "<p>#{answer}</p>",
    )
  end
end
