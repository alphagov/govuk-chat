module SystemSpecHelpers
  def given_i_have_confirmed_i_understand_chat_risks
    visit onboarding_limitations_path

    click_button "I understand"
    click_button "Okay, start chatting"
  end
  alias_method :and_i_have_confirmed_i_understand_chat_risks, :given_i_have_confirmed_i_understand_chat_risks

  def dismiss_cookie_banner
    visit root_path

    within(".gem-c-cookie-banner") do
      click_button "Reject additional cookies"
      click_button "Hide this message"
    end
  end

  def set_rack_cookie(name, value)
    headers = {}
    Rack::Utils.set_cookie_header!(headers, name, value)
    cookie_string = headers["Set-Cookie"]
    Capybara.current_session.driver.browser.set_cookie(cookie_string)
  end

  def given_i_am_an_admin
    login_as(create(:user, :admin))
  end
end
