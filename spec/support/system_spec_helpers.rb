module SystemSpecHelpers
  def given_i_have_confirmed_i_understand_chat_risks
    visit onboarding_confirm_path
    check "confirm_understand_risk_confirmation"
    click_on "Start chatting"
  end
end
