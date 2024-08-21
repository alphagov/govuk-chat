RSpec.describe "Chat Onboarding" do
  scenario "without JS" do
    given_i_am_a_signed_in_early_access_user
    when_i_visit_the_root_path
    then_i_see_the_landing_page

    when_i_click_on_the_try_govuk_chat_button
    then_i_see_the_onboarding_page

    when_i_click_tell_me_more
    then_i_see_additional_information

    when_i_click_that_i_understand
    then_i_see_the_onboarding_privacy_page

    when_i_click_on_the_start_chatting_button
    then_i_see_the_conversation_page
  end

  scenario "with JS", :dismiss_cookie_banner, :js do
    given_i_am_a_signed_in_early_access_user
    when_i_visit_the_root_path
    then_i_see_the_landing_page

    when_i_click_on_the_try_govuk_chat_button
    then_i_see_the_onboarding_page

    when_i_click_tell_me_more
    then_i_see_additional_information

    when_i_click_that_i_understand
    then_i_see_the_onboarding_privacy_page

    when_i_click_on_the_start_chatting_button
    then_i_see_the_chat_prompt
  end

  def when_i_visit_the_root_path
    visit root_path
  end

  def then_i_see_the_landing_page
    expect(page).to have_content("GOV.UK Chat")
  end

  def when_i_click_on_the_try_govuk_chat_button
    click_on "Try GOV.UK Chat"
  end

  def then_i_see_the_onboarding_page
    expect(page).to have_content(/Hello 👋 I’m GOV.UK Chat/)
  end

  def when_i_click_tell_me_more
    click_on "Tell me more"
  end

  def then_i_see_additional_information
    expect(page).to have_content(/I combine the same technology used on ChatGPT with GOV.UK guidance/)
  end

  def when_i_click_that_i_understand
    click_on "I understand"
  end

  def then_i_see_the_onboarding_privacy_page
    expect(page).to have_content(/Great. You can always find information about my limitations in about GOV.UK Chat/)
  end

  def when_i_click_on_the_start_chatting_button
    click_on "Okay, start chatting"
  end

  def then_i_see_the_conversation_page
    expect(page).to have_content("GOV.UK Chat")
  end

  def then_i_see_the_chat_prompt
    expect(page).to have_content(/Okay/)
    expect(page).to have_content(/Thanks! To get started, ask me a question/)

    expect(page).to have_css(".js-conversation-form-group")
  end
end
