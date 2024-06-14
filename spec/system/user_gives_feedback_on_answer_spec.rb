RSpec.describe "User gives feedback on an answer" do
  scenario do
    given_i_have_an_active_conversation_with_an_answered_question
    when_i_visit_the_conversation_page
    and_i_click_that_the_answer_was_useful
    then_i_see_that_my_feedback_was_submitted
  end

  def given_i_have_an_active_conversation_with_an_answered_question
    @conversation = create(:conversation)
    set_cookie(:conversation_id, @conversation.id)
    create(:question, :with_answer, conversation: @conversation)
  end

  def when_i_visit_the_conversation_page
    visit show_conversation_path
  end

  def and_i_click_that_the_answer_was_useful
    click_on "Useful"
  end

  def then_i_see_that_my_feedback_was_submitted
    expect(page).to have_content("Feedback submitted successfully.")
  end
end
