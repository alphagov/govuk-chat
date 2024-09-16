RSpec.describe "Conversation JavaScript features", :chunked_content_index, :dismiss_cookie_banner, :js do
  scenario "questions with answers" do
    given_i_am_a_signed_in_early_access_user
    and_i_have_confirmed_i_understand_chat_risks
    when_i_enter_a_first_question
    then_i_see_the_first_question_was_accepted

    when_the_first_answer_is_generated
    then_i_can_see_the_first_answer

    when_i_enter_a_second_question
    then_i_see_the_second_question_was_accepted

    when_the_second_answer_is_generated
    then_i_can_see_the_second_answer
  end

  scenario "client side validation" do
    given_i_am_a_signed_in_early_access_user
    and_i_have_confirmed_i_understand_chat_risks
    when_i_enter_an_empty_question
    then_i_see_a_presence_validation_message

    when_i_enter_a_valid_question
    then_i_see_the_valid_question_was_accepted
  end

  scenario "server side validation" do
    given_i_am_a_signed_in_early_access_user
    and_i_have_confirmed_i_understand_chat_risks
    when_i_enter_a_question_with_pii
    then_i_see_a_pii_validation_message

    when_i_enter_a_valid_question
    then_i_see_the_valid_question_was_accepted
  end

  scenario "reloading the page while an answer is pending" do
    given_i_am_a_signed_in_early_access_user
    and_i_have_confirmed_i_understand_chat_risks
    when_i_enter_a_first_question
    then_i_see_the_first_question_was_accepted

    when_i_reload_the_page
    and_the_first_answer_is_generated
    then_i_can_see_the_first_answer
  end

  scenario "User gives feedback on an answer" do
    given_i_am_a_signed_in_early_access_user
    and_i_have_confirmed_i_understand_chat_risks
    when_i_enter_a_first_question
    then_i_see_the_first_question_was_accepted

    when_the_first_answer_is_generated
    and_i_click_that_the_answer_was_useful
    then_i_am_thanked_for_my_feedback

    when_i_click_hide_this_message
    then_i_no_longer_see_the_thank_you_message
  end

  scenario "character limits" do
    given_i_am_a_signed_in_early_access_user
    and_i_have_confirmed_i_understand_chat_risks
    when_i_type_in_a_question_approaching_the_character_count_limit
    then_i_see_a_character_count_warning

    when_i_type_in_a_question_exceeding_the_character_count_limit
    then_i_see_a_character_count_error
  end

  scenario "loading messages" do
    given_i_am_a_signed_in_early_access_user
    and_i_have_confirmed_i_understand_chat_risks
    when_i_enter_a_first_question_with_a_slow_response
    then_i_see_a_question_loading_message

    when_i_see_the_first_question_was_accepted
    then_i_see_an_answer_loading_message

    when_the_first_answer_is_generated
    then_i_can_see_the_first_answer
    and_i_see_no_answer_loading_message
  end

  scenario "print link is added to navigation" do
    given_i_am_a_signed_in_early_access_user
    and_i_have_confirmed_i_understand_chat_risks
    then_i_see_a_print_link_in_the_menu
  end

  scenario "reaching question limit" do
    given_i_am_approaching_the_question_limit
    and_i_have_an_active_conversation
    and_i_am_a_signed_in_early_access_user

    when_i_visit_the_conversation_page
    and_i_have_confirmed_i_understand_chat_risks

    when_i_enter_a_first_question
    then_i_see_the_valid_question_was_accepted
    and_the_first_answer_is_generated
    and_i_see_my_question_remaining_count
    and_i_see_an_approaching_question_limit_system_message

    when_i_enter_a_second_question
    then_i_see_the_second_question_was_accepted
    and_the_second_answer_is_generated
    and_i_see_my_question_remaining_count_is_decreased

    when_i_reload_the_page
    then_i_do_not_see_an_approaching_question_limit_system_message
  end

  scenario "reached question limit" do
    given_i_have_one_question_remaining_in_my_limit
    and_i_have_an_active_conversation
    and_i_am_a_signed_in_early_access_user

    when_i_visit_the_conversation_page
    and_i_have_confirmed_i_understand_chat_risks

    when_i_enter_a_first_question
    then_i_see_the_valid_question_was_accepted
    and_the_first_answer_is_generated
    and_i_see_a_reached_question_limit_system_message

    when_i_enter_a_second_question
    then_i_see_a_message_limit_validation_error
  end

  def when_i_enter_a_first_question
    @first_question = "How do I setup a workplace pension?"
    fill_in "create_question[user_question]", with: @first_question
    click_on "Send"
  end
  alias_method :when_i_enter_a_valid_question, :when_i_enter_a_first_question

  def when_i_enter_a_first_question_with_a_slow_response
    @first_question = "How do I setup a workplace pension?"
    conversation = build(:conversation, user: @user)
    prepared_question = create(:question, message: @first_question, conversation:)

    allow(Question).to receive(:new).and_return(prepared_question)
    # delay the server side response to provide time for a delayed loading state
    allow(prepared_question).to receive(:save!) { sleep 1 }

    fill_in "create_question[user_question]", with: @first_question
    click_on "Send"
  end

  def then_i_see_the_first_question_was_accepted
    within(".js-new-conversation-messages-list") do
      expect(page).to have_content(@first_question)
    end
  end
  alias_method :then_i_see_the_valid_question_was_accepted, :then_i_see_the_first_question_was_accepted
  alias_method :when_i_see_the_first_question_was_accepted, :then_i_see_the_valid_question_was_accepted

  def then_i_see_an_answer_loading_message
    within(".js-new-conversation-messages-list") do
      expect(page).to have_content("Loading your answer")
    end
  end

  def and_i_see_no_answer_loading_message
    within(".js-new-conversation-messages-list") do
      expect(page).not_to have_content("Loading your answer")
    end
  end

  def then_i_see_a_question_loading_message
    within(".js-new-conversation-messages-list") do
      expect(page).to have_content("Loading your question")
    end
  end

  def then_i_see_no_question_loading_message
    within(".js-new-conversation-messages-list") do
      expect(page).not_to have_content("Loading your question")
    end
  end

  def when_the_first_answer_is_generated
    @first_answer = "You can use a simple service on GOV.UK"
    answer = {
      "answer" => @first_answer,
      "answered" => true,
      "sources_used" => ["/pensions-service"],
    }.to_json
    stubs_for_mock_answer(@first_question, answer)

    execute_queued_sidekiq_jobs
  end
  alias_method :and_the_first_answer_is_generated, :when_the_first_answer_is_generated

  def then_i_can_see_the_first_answer
    expect(page).to have_content(@first_answer)
  end

  def when_i_enter_a_second_question
    @second_question = "Sounds good, what's the name of the service?"
    fill_in "create_question[user_question]", with: @second_question
    click_on "Send"
  end

  def then_i_see_the_second_question_was_accepted
    within(".js-new-conversation-messages-list") do
      expect(page).to have_content(@second_question)
    end
  end

  def when_the_second_answer_is_generated
    @second_answer = "The simple workplace pension service"
    answer = {
      "answer" => @second_answer,
      "answered" => true,
      "sources_used" => ["/pensions-service"],
    }.to_json

    stubs_for_mock_answer(@second_question, answer, rephrase_question: true)

    execute_queued_sidekiq_jobs
  end
  alias_method :and_the_second_answer_is_generated, :when_the_second_answer_is_generated

  def then_i_can_see_the_second_answer
    expect(page).to have_content(@second_answer)
  end

  def when_i_enter_an_empty_question
    fill_in "create_question[user_question]", with: ""
    click_on "Send"
  end

  def then_i_see_a_presence_validation_message
    expect(page).to have_content(Form::CreateQuestion::USER_QUESTION_PRESENCE_ERROR_MESSAGE)
  end

  def when_i_enter_a_question_with_pii
    fill_in "create_question[user_question]", with: "My phone number is 07123456789"
    click_on "Send"
  end

  def then_i_see_a_pii_validation_message
    expect(page).to have_content(/Personal data has been detected/)
  end

  def when_i_reload_the_page
    refresh
  end

  def and_i_click_that_the_answer_was_useful
    click_on "Useful"
  end

  def then_i_am_thanked_for_my_feedback
    expect(page).to have_content("Thanks for your feedback.")
  end

  def when_i_click_hide_this_message
    click_on "Hide this message"
  end

  def then_i_no_longer_see_the_thank_you_message
    expect(page).not_to have_content("Thanks for your feedback.")
    expect(page).not_to have_content("Hide this message")
  end

  def when_i_type_in_a_question_approaching_the_character_count_limit
    character_count = Form::CreateQuestion::USER_QUESTION_LENGTH_MAXIMUM - 50
    fill_in "create_question[user_question]", with: "A" * character_count
  end

  def when_i_type_in_a_question_exceeding_the_character_count_limit
    character_count = Form::CreateQuestion::USER_QUESTION_LENGTH_MAXIMUM + 10
    fill_in "create_question[user_question]", with: "A" * character_count
  end

  def then_i_see_a_character_count_warning
    expect(page).to have_content("You have 50 characters remaining")
  end

  def then_i_see_a_character_count_error
    expect(page).to have_content("You have 10 characters too many")
  end

  def stubs_for_mock_answer(question, answer, rephrase_question: false)
    if rephrase_question
      rephrased_question = "Rephrased #{question}"

      stub_openai_question_rephrasing(question, rephrased_question)

      question = rephrased_question
    end

    stub_openai_embedding(question)

    populate_chunked_content_index([
      build(:chunked_content_record, openai_embedding: mock_openai_embedding(question)),
    ])

    stub_openai_chat_question_routing(question)
    stub_openai_chat_completion_structured_response(question, answer)

    parsed_answer = JSON.parse(answer)["answer"]
    stub_openai_output_guardrail(parsed_answer)
  end

  def then_i_see_a_print_link_in_the_menu
    within(".app-c-header") do
      click_button "Menu"
    end

    expect(page).to have_button("Print or save this chat")
  end

  def given_i_am_approaching_the_question_limit
    allow(Rails.configuration.conversations).to receive_messages(
      max_questions_per_user: 50,
      question_warning_threshold: 20,
    )
    @user = create(:early_access_user, questions_count: 29)
  end

  def given_i_have_one_question_remaining_in_my_limit
    allow(Rails.configuration.conversations).to receive_messages(
      max_questions_per_user: 50,
      question_warning_threshold: 20,
    )
    @user = create(:early_access_user, questions_count: 49)
  end

  def and_i_see_my_question_remaining_count
    expect(page).to have_content("20 messages left")
  end

  def and_i_see_my_question_remaining_count_is_decreased
    expect(page).to have_content("19 messages left")
  end

  def and_i_see_an_approaching_question_limit_system_message
    within(".js-new-conversation-messages-list:last-child") do
      expect(page).to have_content("You’ve nearly reached the message limit for the GOV.UK Chat trial.")
    end
  end

  def then_i_do_not_see_an_approaching_question_limit_system_message
    expect(page).not_to have_content("You’ve nearly reached the message limit for the GOV.UK Chat trial.")
  end

  def and_i_see_a_reached_question_limit_system_message
    within(".js-new-conversation-messages-list:last-child") do
      expect(page).to have_content("You’ve reached the message limit for the GOV.UK Chat trial.")
    end
  end

  def then_i_see_a_message_limit_validation_error
    within(".app-c-question-form__error-list") do
      expect(page).to have_content "You have asked the maximum number of questions"
    end
  end

  def and_i_have_an_active_conversation
    create(:conversation, user: @user)
  end

  def when_i_visit_the_conversation_page
    visit show_conversation_path
  end
end
