RSpec.describe "Conversation with Claude with a structured answer" do
  scenario do
    given_i_am_using_the_claude_structured_answer_strategy
    and_i_am_a_signed_in_early_access_user
    and_i_have_confirmed_i_understand_chat_risks

    when_i_visit_the_conversation_page
    and_i_enter_a_question
    then_i_see_the_answer_is_pending

    when_the_first_answer_is_generated
    and_i_click_on_the_check_answer_button
    then_i_see_my_question_on_the_page
    and_i_can_see_the_first_answer

    when_i_enter_a_second_question
    then_i_see_the_answer_is_pending

    when_the_second_answer_is_generated
    and_i_click_on_the_check_answer_button
    then_i_see_my_second_question_on_the_page
    and_i_can_see_the_second_answer
  end

  def when_i_visit_the_conversation_page
    visit show_conversation_path
  end

  def and_i_enter_a_question
    @first_question = "How much tax should I be paying?"
    fill_in "Message", with: @first_question
    click_on "Send"
  end

  def then_i_see_the_answer_is_pending
    expect(page).to have_content("GOV.UK Chat is generating an answer")
  end

  def when_the_first_answer_is_generated
    @first_answer = "Lots of tax."
    stub_bedrock_converse(
      bedrock_claude_structured_answer_response(@first_question, @first_answer),
    )
    execute_queued_sidekiq_jobs
  end

  def and_i_click_on_the_check_answer_button
    click_on "Check if an answer has been generated"
  end

  def then_i_see_my_question_on_the_page
    expect(page).to have_content(@first_question)
  end

  def and_i_can_see_the_first_answer
    expect(page).to have_content(@first_answer)
  end

  def when_i_enter_a_second_question
    @second_question = "Are you sure?"
    fill_in "Message", with: @second_question
    click_on "Send"
  end

  def when_the_second_answer_is_generated
    @second_answer = "Even more tax."
    stub_bedrock_converse(
      bedrock_claude_structured_answer_response(@second_question, @second_answer),
    )
    execute_queued_sidekiq_jobs
  end

  def then_i_see_my_second_question_on_the_page
    expect(page).to have_content(@second_question)
  end

  def and_i_can_see_the_second_answer
    expect(page).to have_content(@second_answer)
  end
end
