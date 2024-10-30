module SystemSpecHelpers
  def given_i_have_confirmed_i_understand_chat_risks
    visit onboarding_limitations_path

    click_button "I understand"
    click_button "Okay, start chatting"
  end
  alias_method :and_i_have_confirmed_i_understand_chat_risks, :given_i_have_confirmed_i_understand_chat_risks

  def dismiss_cookie_banner
    visit homepage_path

    within(".gem-c-cookie-banner") do
      click_button "Reject additional cookies"
      click_button "Hide this message"
    end
  end

  def set_rack_cookie(name, value)
    cookie_string = Rack::Utils.set_cookie_header(name, value)
    Capybara.current_session.driver.browser.set_cookie(cookie_string)
  end

  def given_i_am_an_admin
    login_as(create(:admin_user, :admin))
  end

  def extract_links_from_last_email
    email_body = ActionMailer::Base.deliveries.last.body.raw_source
    # URI.extract infers that the closing link markdown parenthesis ")" is part of the href
    URI.extract(email_body).map { |link| link.gsub(")", "") }
  end

  def given_i_am_a_signed_in_early_access_user
    @user ||= create(:early_access_user)
    session = Passwordless::Session.create!(authenticatable: @user)
    magic_link = magic_link_path(session.to_param, session.token, only_path: false)
    visit(magic_link)
  end
  alias_method :and_i_am_a_signed_in_early_access_user, :given_i_am_a_signed_in_early_access_user

  def ur_question_first_option_text(question_label)
    Rails.configuration.pilot_user_research_questions.dig(question_label, :options, 0, :text)
  end
end
