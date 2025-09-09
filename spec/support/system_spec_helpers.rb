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

  def given_i_am_using_the_openai_structured_answer_strategy
    allow(Rails.configuration)
      .to receive(:answer_strategy)
      .and_return("openai_structured_answer")
  end

  def given_i_have_dismissed_the_cookie_banner
    visit homepage_path

    within(".gem-c-cookie-banner") do
      click_button "Reject additional cookies"
      click_button "Hide cookie message"
    end
  end
  alias_method :and_i_have_dismissed_the_cookie_banner, :given_i_have_dismissed_the_cookie_banner

  def set_rack_cookie(name, value)
    cookie_string = Rack::Utils.set_cookie_header(name, value)
    Capybara.current_session.driver.browser.set_cookie(cookie_string)
  end

  def given_i_am_an_admin
    login_as(create(:signon_user, :admin))
  end

  def given_i_am_an_admin_with_the_settings_permission
    login_as(create(:signon_user, :admin_area_settings))
  end

  def ur_question_first_option_text(question_label)
    Rails.configuration.pilot_user_research_questions.dig(question_label, :options, 0, :text)
  end
end
