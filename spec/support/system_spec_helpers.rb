module SystemSpecHelpers
  def given_i_have_confirmed_i_understand_chat_risks
    visit onboarding_limitations_path
    click_on "I understand"
    click_on "Okay, start chatting"
  end
end
