RSpec.describe "Sign in" do
  scenario "active user signs in" do
    given_sign_ups_are_enabled
    and_i_am_a_returning_user

    when_i_visit_the_homepage
    and_i_enter_my_email_address
    then_i_am_told_i_have_been_sent_an_email

    when_i_click_the_link_in_the_email
    then_i_arrive_on_the_onboarding_limitations_page

    when_i_click_the_header_logo
    then_i_see_a_signed_in_homepage

    when_i_sign_out
    then_i_see_i_am_signed_out
    and_trying_to_visit_a_conversation_redirects_me_to_the_homepage
  end

  scenario "revoked user attempts to sign in" do
    given_sign_ups_are_enabled
    and_i_am_a_returning_user_with_revoked_access

    when_i_visit_the_homepage
    and_i_enter_my_email_address
    then_i_am_told_i_do_not_have_access
  end

  scenario "early access user unsubscribes" do
    given_sign_ups_are_enabled
    and_i_am_a_returning_user

    when_i_visit_the_homepage
    and_i_enter_my_email_address
    then_i_am_told_i_have_been_sent_an_email

    when_i_click_the_unsubscribe_link_in_the_email
    then_i_see_my_early_access_account_has_been_removed
  end

  scenario "returning user signs in and can clear chat" do
    given_i_am_not_signed_in
    and_i_have_an_active_conversation_with_an_answered_question

    when_i_sign_in_via_magic_link
    and_i_choose_to_start_a_new_chat
    then_i_cannot_see_my_previous_questions_and_answer
  end

  def given_i_am_not_signed_in
    @user = create :early_access_user
  end

  def given_sign_ups_are_enabled
    @settings = create(:settings, sign_up_enabled: true)
  end

  def and_i_am_a_returning_user
    user = create(:early_access_user)
    @email = user.email
  end

  def and_i_am_a_returning_user_with_revoked_access
    user = create(:early_access_user, :revoked)
    @email = user.email
  end

  def when_i_visit_the_homepage
    visit homepage_path
  end

  def and_i_enter_my_email_address
    @email ||= "user@test.com"
    fill_in "Enter your email to sign up or get a new link for GOV.UK Chat", with: @email
    click_on "Get started"
  end

  def then_i_am_told_i_have_been_sent_an_email
    expect(page).to have_content("You have been sent a new unique link to access GOV.UK Chat.")
  end

  def when_i_click_the_link_in_the_email
    email_links = extract_links_from_last_email
    visit email_links.first
  end

  def when_i_click_the_unsubscribe_link_in_the_email
    email_links = extract_links_from_last_email
    visit email_links.last
  end

  def then_i_arrive_on_the_onboarding_limitations_page
    expect(page).to have_content("Introduction to GOV.UK Chat and its limitations")
  end

  def then_i_see_i_am_signed_out
    expect(page).to have_content("You are now signed out")
  end

  def then_i_am_told_i_do_not_have_access
    expect(page).to have_content("You do not have access to GOV.UK Chat.")
  end

  def when_i_sign_out
    within(".app-c-header") do
      click_link "Sign out"
    end
  end

  def and_trying_to_visit_a_conversation_redirects_me_to_the_homepage
    visit show_conversation_path

    expect(page).to have_current_path(homepage_path)
  end

  def then_i_see_my_early_access_account_has_been_removed
    expect(page).to have_content("Your access has been removed")
    expect(EarlyAccessUser.exists?(email: @email)).to be(false)
  end

  def and_i_have_an_active_conversation_with_an_answered_question
    @conversation = create(:conversation, user: @user)
    set_rack_cookie(:conversation_id, @conversation.id)
    answer = build(:answer, message: "Example answer")
    create(:question, answer:, conversation: @conversation, message: "Example question")
  end

  def when_i_sign_in_via_magic_link
    session = create :passwordless_session, authenticatable: @user
    magic_link = magic_link_path(session.to_param, session.token)
    visit magic_link
  end

  def and_i_choose_to_start_a_new_chat
    click_button "Start a new chat (clears last chat)"
  end

  def then_i_cannot_see_my_previous_questions_and_answer
    expect(page).not_to have_content("Example question")
    expect(page).not_to have_content("Example answer")
  end

  def when_i_click_the_header_logo
    within(".app-c-header") do
      click_link "Chat"
    end
  end

  def then_i_see_a_signed_in_homepage
    expect(page).to have_content("You are currently signed in with #{@email}")
  end
end
