RSpec.describe "Sign ups" do
  scenario "new user signs up" do
    given_sign_ups_are_enabled

    when_i_visit_the_homepage
    and_i_enter_my_email_address
    and_i_choose_my_description
    and_i_choose_my_reason_for_visit
    then_i_am_told_i_have_been_sent_an_email

    when_i_click_the_link_in_the_email
    then_i_arrive_on_the_onboarding_limitations_page
  end

  scenario "returning user signs in" do
    given_sign_ups_are_enabled
    and_i_am_a_returning_user

    when_i_visit_the_homepage
    and_i_enter_my_email_address
    then_i_am_told_i_have_been_sent_an_email

    when_i_click_the_link_in_the_email
    then_i_arrive_on_the_onboarding_limitations_page
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

  scenario "revoked user attempts to sign in" do
    given_sign_ups_are_enabled
    and_i_am_a_returning_user_with_revoked_access

    when_i_visit_the_homepage
    and_i_enter_my_email_address
    then_i_am_told_i_do_not_have_access
  end

  scenario "signups are disabled by an admin mid flow" do
    given_sign_ups_are_enabled
    when_i_visit_the_homepage
    and_i_enter_my_email_address
    and_an_admin_toggles_off_signups
    and_i_choose_my_description
    then_i_see_the_signups_are_disabled_page
  end

  scenario "no instant access places are available" do
    given_sign_ups_are_enabled
    and_there_are_no_instant_access_places_available

    when_i_visit_the_homepage
    and_i_enter_my_email_address
    and_i_choose_my_description
    and_i_choose_my_reason_for_visit

    then_i_am_told_i_have_been_added_to_the_waitlist
    and_i_receive_an_email_telling_me_i_am_on_the_waitlist
  end

  scenario "waiting list user unsubscribes" do
    given_sign_ups_are_enabled
    and_there_are_no_instant_access_places_available

    when_i_visit_the_homepage
    and_i_enter_my_email_address
    and_i_choose_my_description
    and_i_choose_my_reason_for_visit
    then_i_am_told_i_have_been_added_to_the_waitlist

    when_i_click_the_unsubscribe_link_in_the_email
    then_i_see_my_waiting_list_place_has_been_removed
  end

  scenario "answering the first question incorrectly" do
    given_sign_ups_are_enabled
    when_i_visit_the_homepage
    and_i_enter_my_email_address
    and_i_choose_an_invalid_description
    and_i_choose_my_reason_for_visit
    then_i_am_told_i_have_been_prevented_access
  end

  def given_sign_ups_are_enabled
    @settings = create(:settings, sign_up_enabled: true)
  end

  def when_i_visit_the_homepage
    visit homepage_path
  end

  def and_i_enter_my_email_address
    fill_in "Enter your email to sign up or get a new link for GOV.UK Chat", with: @email ||= "user@test.com"
    click_on "Get started"
  end

  def and_i_choose_my_description
    choose "I own a business or am self-employed"
    click_on "Next question"
  end

  def and_i_choose_an_invalid_description
    choose "None of the above"
    click_on "Next question"
  end

  def and_i_choose_my_reason_for_visit
    choose "To complete a task, like applying for a passport"
    click_on "Submit answers"
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

  def and_i_am_a_returning_user
    user = create(:early_access_user)
    @email = user.email
  end

  def and_i_am_a_returning_user_with_revoked_access
    user = create(:early_access_user, :revoked)
    @email = user.email
  end

  def then_i_see_my_early_access_account_has_been_removed
    expect(page).to have_content("Your access has been removed")
    expect(EarlyAccessUser.exists?(email: @email)).to be(false)
  end

  def then_i_see_my_waiting_list_place_has_been_removed
    expect(page).to have_content("You’ve been removed from the waitlist")
    expect(WaitingListUser.exists?(email: @email)).to be(false)
  end

  def then_i_am_told_i_do_not_have_access
    expect(page).to have_content("You do not have access to GOV.UK Chat.")
  end

  def and_an_admin_toggles_off_signups
    @settings.update!(sign_up_enabled: false)
  end

  def then_i_see_the_signups_are_disabled_page
    expect(page).to have_content("Sign up is currently closed")
  end

  def and_there_are_no_instant_access_places_available
    Settings.instance.update!(instant_access_places: 0)
  end

  def then_i_am_told_i_have_been_added_to_the_waitlist
    expect(page).to have_content("You have been added to the waitlist")
  end

  def and_i_receive_an_email_telling_me_i_am_on_the_waitlist
    expect(ActionMailer::Base.deliveries.last.body.raw_source)
      .to include("You've been added to the GOV.UK Chat waitlist")
  end

  def then_i_am_told_i_have_been_prevented_access
    expect(page).to have_content("You cannot currently use GOV.UK Chat")
  end
end
