module SystemSpecHelpers
  def given_i_am_a_web_chat_user
    @signon_user = create(:signon_user, :web_chat)
    login_as(@signon_user)
  end

  def given_i_am_using_the_claude_structured_answer_strategy
    allow(Rails.configuration)
      .to receive(:answer_strategy)
      .and_return("claude_structured_answer")
  end

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
    login_as(create(:signon_user, :admin))
  end

  def ur_question_first_option_text(question_label)
    Rails.configuration.pilot_user_research_questions.dig(question_label, :options, 0, :text)
  end
end
