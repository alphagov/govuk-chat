RSpec.describe "Conversation JavaScript features", :aws_credentials_stubbed, :chunked_content_index, :js do
  scenario "questions with answers" do
    given_i_am_a_web_chat_user
    and_i_have_dismissed_the_cookie_banner

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
    given_i_am_a_web_chat_user
    and_i_have_dismissed_the_cookie_banner

    when_i_visit_the_conversation_page
    and_i_enter_an_empty_question
    then_i_see_a_presence_validation_message

    when_i_enter_a_valid_question
    then_i_see_the_valid_question_was_accepted
  end

  scenario "server side validation" do
    given_i_am_a_web_chat_user
    and_i_have_dismissed_the_cookie_banner

    when_i_visit_the_conversation_page
    and_i_enter_a_question_with_pii
    then_i_see_a_pii_validation_message

    when_i_enter_a_valid_question
    then_i_see_the_valid_question_was_accepted
  end

  scenario "reloading the page while an answer is pending" do
    given_i_am_a_web_chat_user
    and_i_have_dismissed_the_cookie_banner

    when_i_visit_the_conversation_page
    and_i_enter_a_first_question
    then_i_see_the_first_question_was_accepted

    when_i_reload_the_page
    and_the_first_answer_is_generated
    then_i_can_see_the_first_answer
  end

  scenario "User gives feedback on an answer" do
    given_i_am_a_web_chat_user
    and_i_have_dismissed_the_cookie_banner

    when_i_visit_the_conversation_page
    and_i_enter_a_first_question
    then_i_see_the_first_question_was_accepted

    when_the_first_answer_is_generated
    and_i_click_that_the_answer_was_useful
    then_i_am_thanked_for_my_feedback
  end

  scenario "character limits" do
    given_i_am_a_web_chat_user
    and_i_have_dismissed_the_cookie_banner

    when_i_visit_the_conversation_page
    and_i_type_in_a_question_approaching_the_character_count_limit
    then_i_see_a_character_count_warning

    when_i_type_in_a_question_exceeding_the_character_count_limit
    then_i_see_a_character_count_error
  end

  scenario "loading messages" do
    given_i_am_a_web_chat_user
    and_i_have_dismissed_the_cookie_banner

    when_i_visit_the_conversation_page
    and_i_enter_a_first_question_with_a_slow_response
    then_i_see_a_question_loading_message

    when_i_see_the_first_question_was_accepted
    then_i_see_an_answer_loading_message

    when_the_first_answer_is_generated
    then_i_can_see_the_first_answer
    and_i_see_no_answer_loading_message
  end

  scenario "showing clear chat link in navigation" do
    given_i_am_a_web_chat_user
    and_i_have_dismissed_the_cookie_banner

    when_i_visit_the_conversation_page
    then_i_cant_see_the_clear_chat_link

    when_i_enter_a_first_question
    then_i_see_the_first_question_was_accepted
    and_i_can_see_the_clear_chat_link
  end

  def when_i_visit_the_conversation_page
    visit show_conversation_path
  end

  def when_i_enter_a_first_question
    @first_question = "How do I setup a workplace pension?"
    fill_in "create_question[user_question]", with: @first_question
    click_on "Send"
  end
  alias_method :when_i_enter_a_valid_question, :when_i_enter_a_first_question
  alias_method :and_i_enter_a_first_question, :when_i_enter_a_first_question

  def and_i_enter_a_first_question_with_a_slow_response
    @first_question = "How do I setup a workplace pension?"
    conversation = build(:conversation, signon_user: @signon_user)
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
      expect(page).to have_content("Generating your answer")
    end
  end

  def and_i_see_no_answer_loading_message
    within(".js-new-conversation-messages-list") do
      expect(page).not_to have_content("Generating your answer")
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
    stubs_for_mock_answer(@first_question,
                          @first_answer,
                          answered: true,
                          sources_used: %w[link_1])

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

    stubs_for_mock_answer(@second_question,
                          @second_answer,
                          rephrase_question: true,
                          answered: true,
                          sources_used: %w[link_1],
                          create_content_chunk: false)

    execute_queued_sidekiq_jobs
  end
  alias_method :and_the_second_answer_is_generated, :when_the_second_answer_is_generated

  def then_i_can_see_the_second_answer
    expect(page).to have_content(@second_answer)
  end

  def and_i_enter_an_empty_question
    fill_in "create_question[user_question]", with: ""
    click_on "Send"
  end

  def then_i_see_a_presence_validation_message
    expect(page).to have_content(Form::CreateQuestion::USER_QUESTION_PRESENCE_ERROR_MESSAGE)
  end

  def and_i_enter_a_question_with_pii
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

  def and_i_type_in_a_question_approaching_the_character_count_limit
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

  def stubs_for_mock_answer(question,
                            answer,
                            rephrase_question: false,
                            answered: true,
                            sources_used: [],
                            create_content_chunk: true)
    stub_claude_jailbreak_guardrails(question, triggered: false)

    if rephrase_question
      rephrased_question = "Rephrased #{question}"

      stub_claude_question_rephrasing(question, rephrased_question)

      question = rephrased_question
    end

    stub_bedrock_titan_embedding(question)

    if create_content_chunk
      populate_chunked_content_index([
        build(:chunked_content_record, titan_embedding: mock_titan_embedding(question)),
      ])
    end

    stub_claude_question_routing(question)
    stub_claude_structured_answer(question, answer, answered:, sources_used:)

    stub_claude_output_guardrails(answer)
    stub_claude_messages_topic_tagger(question)
    stub_bedrock_invoke_model_openai_oss_answer_relevancy(
      question_message: question,
      answer_message: answer,
    )
    stub_bedrock_invoke_model_openai_oss_faithfulness(
      retrieval_context: "Some content",
      answer_message: answer,
    )
    stub_bedrock_invoke_model_openai_oss_coherence(
      question_message: question,
      answer_message: answer,
    )
    stub_bedrock_invoke_model_openai_oss_context_relevancy(
      question_message: question,
    )
  end

  def then_i_cant_see_the_clear_chat_link
    within(".app-c-header") do
      # This is link is visually hidden but doesn't register as visible: :hidden
      # to capybara so have to assert on CSS selector
      expect(page).to have_selector(
        "a.app-c-header__clear-chat.app-c-header__clear-chat--focusable-only",
        text: "Clear chat",
      )
    end
  end

  def and_i_can_see_the_clear_chat_link
    within(".app-c-header") do
      expect(page).to have_selector(
        "a.app-c-header__clear-chat:not(.app-c-header__clear-chat--focusable-only)",
        text: "Clear chat",
      )
    end
  end

  def when_i_visit_the_conversation_page
    visit show_conversation_path
  end
end
