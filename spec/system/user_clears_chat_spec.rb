RSpec.describe "User clears chat" do
  scenario do
    given_i_am_signed_in
    and_i_have_an_active_conversation_with_an_answered_question
    and_i_visit_the_conversation_page
    when_i_click_the_clear_chat_link
    and_i_cancel
    then_i_can_see_my_previous_questions_and_answer
    when_i_click_the_clear_chat_link
    and_i_reset_my_conversation
    then_i_cannot_see_my_previous_questions_and_answer
  end

  def and_i_have_an_active_conversation_with_an_answered_question
    @conversation = create(:conversation, signon_user: @signon_user)
    set_rack_cookie(:conversation_id, @conversation.id)
    answer = build(:answer, message: "Example answer")
    create(:question, answer:, conversation: @conversation, message: "Example question")
  end

  def and_i_visit_the_conversation_page
    visit show_conversation_path
  end

  def when_i_click_the_clear_chat_link
    click_on "Start new chat"
  end

  def and_i_cancel
    click_on "Return to last chat"
  end

  def and_i_reset_my_conversation
    click_on "Start a new chat (clears last chat)"
  end

  def then_i_can_see_my_previous_questions_and_answer
    expect(page).to have_content("Example question")
    expect(page).to have_content("Example answer")
  end

  def then_i_cannot_see_my_previous_questions_and_answer
    expect(page).not_to have_content("Example question")
    expect(page).not_to have_content("Example answer")
  end
end
