RSpec.describe "Admin user views conversation history" do
  scenario do
    given_i_am_an_admin
    and_there_are_questions_submitted
    when_i_visit_the_admin_area
    and_i_browse_to_the_questions_section
    then_i_see_the_most_recent_questions
    when_i_click_to_view_a_question
    then_i_see_that_questions_answer
    when_i_click_to_view_conversation
    then_i_see_the_other_questions_for_this_conversation
  end

  def given_i_am_an_admin
    login_as(create(:admin_user, :admin))
  end

  def and_there_are_questions_submitted
    conversation = build(:conversation)
    @question1 = create(:question, conversation:)
    @question2 = create(:question, :with_answer, conversation:)
    @question3 = create(:question)
  end

  def when_i_visit_the_admin_area
    visit admin_homepage_path
  end

  def and_i_browse_to_the_questions_section
    click_link "Questions"
  end

  def then_i_see_the_most_recent_questions
    expect(page).to have_content(@question1.message)
    expect(page).to have_content(@question2.message)
    expect(page).to have_content(@question3.message)
  end

  def when_i_click_to_view_a_question
    click_link @question2.message
  end

  def then_i_see_that_questions_answer
    expect(page).to have_content(@question2.answer.message)
  end

  def when_i_click_to_view_conversation
    click_link @question2.conversation_id
  end

  def then_i_see_the_other_questions_for_this_conversation
    expect(page).to have_content(@question1.message)
    expect(page).to have_content(@question2.message)
    expect(page).not_to have_content(@question3.message)
  end
end
