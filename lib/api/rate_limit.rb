class Api::RateLimit
  GOVUK_API_USER_DEFAULT_THROTTLE_NAME = "default requests to Conversations API with token".freeze
  GOVUK_API_USER_CONVERSATION_WRITE_THROTTLE_NAME = "conversation write requests to Conversations API with token".freeze
  GOVUK_END_USER_DEFAULT_THROTTLE_NAME = "default requests to Conversations API with user id".freeze
  GOVUK_END_USER_CONVERSATION_WRITE_THROTTLE_NAME = "conversation write requests to Conversations API with user id".freeze

  CONVERSATION_API_PATH_REGEX = /^\/api\/v\d+\/conversation/
  CONVERSATION_API_CREATE_PATH_REGEX = /^\/api\/v\d+\/conversation$/
  CONVERSATION_API_UPDATE_PATH_REGEX = /^\/api\/v\d+\/conversation\/[^\/]+$/

  def self.conversation_write?(request)
    create_conversation?(request) || update_conversation?(request)
  end

  def self.default?(request)
    conversation_api_request?(request) && !conversation_write?(request)
  end

  def self.conversation_api_request?(request)
    request.path.match?(CONVERSATION_API_PATH_REGEX)
  end

  def self.create_conversation?(request)
    request.post? && request.path.match?(CONVERSATION_API_CREATE_PATH_REGEX)
  end

  def self.update_conversation?(request)
    request.put? && request.path.match?(CONVERSATION_API_UPDATE_PATH_REGEX)
  end
end
