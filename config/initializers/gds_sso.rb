GDS::SSO.config do |config|
  config.intercept_401_responses = false
  config.user_model = "SignonUser"
end
