class Api::RateLimit
  GOVUK_API_USER_READ_THROTTLE_NAME = "read requests to Conversations API with token".freeze
  GOVUK_API_USER_WRITE_THROTTLE_NAME = "write method requests to Conversations API with token".freeze
  GOVUK_CLIENT_DEVICE_READ_THROTTLE_NAME = "read requests to Conversations API with device id".freeze
  GOVUK_CLIENT_DEVICE_WRITE_THROTTLE_NAME = "write requests to Conversations API with device id".freeze
end
