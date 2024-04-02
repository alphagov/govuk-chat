RSpec.describe "Chat Onboarding" do
  scenario do
    when_i_visit_the_root_path
    then_i_see_the_landing_page

    when_i_click_on_the_continue_button
    then_i_see_the_onboarding_page

    when_i_check_the_inaccuracies_check_box
    and_i_click_on_the_start_chatting_button
    then_i_see_the_conversation_page
  end

  def when_i_visit_the_root_path
    visit root_path
  end

  def then_i_see_the_landing_page
    expect(page).to have_content("Welcome to GOV.UK Chat")
  end

  def when_i_click_on_the_continue_button
    click_on "Continue"
  end

  def then_i_see_the_onboarding_page
    expect(page).to have_content("Before you start")
  end

  def when_i_check_the_inaccuracies_check_box
    check "confirm_understand_risk_confirmation"
  end

  def and_i_click_on_the_start_chatting_button
    click_on "Start chatting"
  end

  def then_i_see_the_conversation_page
    expect(page).to have_content("GOV.UK Chat")
  end
end
