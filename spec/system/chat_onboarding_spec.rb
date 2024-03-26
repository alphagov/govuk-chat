RSpec.feature "Chat Onboarding" do
  scenario do
    when_a_user_visits_root_path
    then_they_see_the_landing_page

    when_the_user_clicks_on_the_continue_button
    then_they_see_the_conversation_page
  end

  def when_a_user_visits_root_path
    visit root_path
  end

  def then_they_see_the_landing_page
    expect(page).to have_content("Welcome to GOV.UK Chat")
  end

  def when_the_user_clicks_on_the_continue_button
    click_on "Continue"
  end

  # TODO: This will change to a different page
  def then_they_see_the_conversation_page
    expect(page).to have_content("GOV.UK Chat")
  end
end
