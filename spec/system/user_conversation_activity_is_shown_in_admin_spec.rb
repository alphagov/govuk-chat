RSpec.describe "Users interactions with chat are shown in admin area", :aws_credentials_stubbed, :chunked_content_index do
  scenario do
    given_i_am_an_admin_with_the_web_chat_permission
    when_i_visit_the_conversation_page
    and_i_enter_a_question
    and_the_answer_is_generated
    and_i_click_on_the_check_answer_button
    and_i_click_that_the_answer_was_useful
    then_i_see_that_my_feedback_was_submitted

    when_i_visit_the_admin_area
    and_i_browse_to_the_questions_section
    and_i_click_on_my_question
    then_i_see_the_answer
    and_i_see_the_answer_feedback

    when_i_click_the_analysis_tab
    then_i_see_the_topics_have_been_tagged
  end

  def given_i_am_an_admin_with_the_web_chat_permission
    login_as(create(:signon_user, permissions: %w[admin-area web-chat]))
  end

  def when_i_visit_the_conversation_page
    visit show_conversation_path
  end

  def and_i_enter_a_question
    @question = "Should I open a business and what benefits could I claim if I do?"
    fill_in "Message", with: @question
    click_on "Send"
  end

  def and_the_answer_is_generated
    titan_embedding = mock_titan_embedding(@question)
    allow(Search::TextToEmbedding)
      .to receive(:call)
      .and_return(titan_embedding)

    populate_chunked_content_index([
      build(:chunked_content_record, titan_embedding:, exact_path: "/pay-more-tax#yes-really"),
    ])

    @answer = "Maybe. You could get some benefits."

    stub_claude_jailbreak_guardrails(@question, triggered: false)
    stub_claude_question_routing(@question)
    stub_claude_structured_answer(@question, @answer)
    stub_claude_output_guardrails(@answer, "False | None")
    stub_claude_messages_topic_tagger(@question)

    execute_queued_sidekiq_jobs
  end

  def and_i_click_on_the_check_answer_button
    click_on "Check if an answer has been generated"
  end

  def and_i_click_that_the_answer_was_useful
    click_on "Useful"
  end

  def then_i_see_that_my_feedback_was_submitted
    expect(page).to have_content("Feedback submitted successfully.")
  end

  def when_i_visit_the_admin_area
    visit admin_homepage_path
  end

  def and_i_browse_to_the_questions_section
    click_link "Questions"
  end

  def and_i_click_on_my_question
    click_link @question
  end

  def then_i_see_the_answer
    expect(page).to have_content(@answer)
  end

  def and_i_see_the_answer_feedback
    expect(page).to have_content("Useful")
  end

  def when_i_click_the_analysis_tab
    click_link "Analysis"
  end

  def then_i_see_the_topics_have_been_tagged
    expect(page).to have_content("Business")
    expect(page).to have_content("Benefits")
  end
end
