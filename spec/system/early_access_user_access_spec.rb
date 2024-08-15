RSpec.describe "Early access user access" do
  scenario "new user signs up" do
    when_i_visit_the_early_access_signup_page
    and_i_enter_my_email_address
    and_i_choose_my_description
    and_i_choose_my_reason_for_visit
    then_i_am_told_i_have_been_sent_an_email_address

    when_i_click_the_link_in_the_email
    then_i_arrive_on_the_onboarding_limitations_page
  end

  scenario "returning user signs in" do
    given_i_am_a_returning_user
    when_i_visit_the_early_access_signup_page
    and_i_enter_my_email_address
    then_i_am_told_i_have_been_sent_an_email_address

    when_i_click_the_link_in_the_email
    then_i_arrive_on_the_onboarding_limitations_page
  end

  scenario "revoked user attempts to sign in" do
    given_i_am_a_returning_user_with_revoked_access
    when_i_visit_the_early_access_signup_page
    and_i_enter_my_email_address
    then_i_am_told_i_do_not_have_access
  end

  def when_i_visit_the_early_access_signup_page
    visit early_access_entry_sign_in_or_up_path
  end

  def and_i_enter_my_email_address
    fill_in "To get started, enter your email address.", with: @email ||= "user@test.com"
    click_on "Get started"
  end

  def and_i_choose_my_description
    choose "I own a business or am self-employed"
    click_on "Next question"
  end

  def and_i_choose_my_reason_for_visit
    choose "To complete a task, like applying for a passport"
    click_on "Submit answers"
  end

  def then_i_am_told_i_have_been_sent_an_email_address
    expect(page).to have_content("You have been sent a new unique link to access GOV.UK Chat.")
  end

  def when_i_click_the_link_in_the_email
    email_body = ActionMailer::Base.deliveries.last.body.raw_source
    # URI.extract infers that the closing link markdown parenthesis ")" is part of the href
    magic_link = URI.extract(email_body).first.gsub(")", "")
    visit magic_link
  end

  def then_i_arrive_on_the_onboarding_limitations_page
    expect(page).to have_content("Introduction to GOV.UK Chat and its limitations")
  end

  def given_i_am_a_returning_user
    user = create(:early_access_user)
    @email = user.email
  end

  def given_i_am_a_returning_user_with_revoked_access
    user = create(:early_access_user, :revoked)
    @email = user.email
  end

  def then_i_am_told_i_do_not_have_access
    expect(page).to have_content("You do not have access to GOV.UK Chat.")
  end
end
