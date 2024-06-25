module SystemSpecHelpers
  def given_i_have_confirmed_i_understand_chat_risks
    visit onboarding_limitations_path
    click_on "I understand"
    click_on "Okay, start chatting"
  end

  def set_cookie(name, value)
    headers = {}
    Rack::Utils.set_cookie_header!(headers, name, value)
    cookie_string = headers["Set-Cookie"]
    Capybara.current_session.driver.browser.set_cookie(cookie_string)
  end
end
