module AuthenticationHelpers
  def login_as(user)
    allow(GDS::SSO).to receive(:test_user).and_return(user)
    Capybara.reset_sessions!
    reset!
  end
end
