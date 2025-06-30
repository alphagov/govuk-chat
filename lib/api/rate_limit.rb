class Api::RateLimit
  GOVUK_API_USER_READ_THROTTLE_NAME = "read requests to Conversations API with token".freeze
  GOVUK_API_USER_WRITE_THROTTLE_NAME = "write method requests to Conversations API with token".freeze
  GOVUK_END_USER_READ_THROTTLE_NAME = "read requests to Conversations API with user id".freeze
  GOVUK_END_USER_WRITE_THROTTLE_NAME = "write requests to Conversations API with user id".freeze
end
