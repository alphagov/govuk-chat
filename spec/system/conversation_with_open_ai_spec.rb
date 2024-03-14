RSpec.feature "Conversation with OpenAI", :sidekiq_inline do
  before do
    stub_open_ai_flag_active
  end

  scenario do
    when_a_user_visits_the_homepage
    and_they_enter_a_question
    then_they_see_their_question_on_the_page
    and_they_can_see_the_answer
  end

  def stub_open_ai_flag_active
    allow(AnonymousUser).to receive(:new).and_return(AnonymousUser.new("known-user"))
    Flipper.enable_actor(:open_ai, AnonymousUser.new("known-user"))
  end

  def when_a_user_visits_the_homepage
    visit root_path
  end

  def and_they_enter_a_question
    fill_in "Enter a question", with: "How much tax should I be paying?"
    click_on "Submit"
  end

  def when_the_user_clicks_on_the_check_answer_button
    click_on "Check if an answer has been generated"
  end

  def then_they_see_their_question_on_the_page
    expect(page).to have_content("How much tax should I be paying?")
  end

  def and_they_can_see_the_answer
    expect(page).to have_content("Answer from OpenAI")
  end
end
