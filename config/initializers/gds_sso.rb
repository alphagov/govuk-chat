GDS::SSO.config do |config|
  config.intercept_401_responses = false
  config.user_model = "SignonUser"
  config.api_request_matcher = ->(request) { request.path.start_with?("/api/") }
  # despite the broad name this config option only applies to the dummy bearer token user created in dev/test
  config.additional_mock_permissions_required = %w[conversation-api]
end
