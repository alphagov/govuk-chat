RSpec.describe "Sign in" do
  scenario "active user signs in" do
    given_sign_ups_are_enabled
    and_i_am_a_returning_user

    when_i_visit_the_homepage
    and_i_enter_my_email_address
    then_i_am_told_i_have_been_sent_an_email

    when_i_click_the_link_in_the_email
    then_i_arrive_on_the_onboarding_limitations_page

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
end
