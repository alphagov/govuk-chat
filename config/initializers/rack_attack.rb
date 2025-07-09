require "api/rate_limit"
require "api/rate_limit/middleware"

Rails.application.config.middleware.insert_after ActionDispatch::Executor, Api::RateLimit::Middleware

class Rack::Attack
  CONVERSATION_API_PATH_REGEX = /^\/api\/v\d+\/conversation/

  throttle(Api::RateLimit::GOVUK_API_USER_READ_THROTTLE_NAME, limit: 10_000, period: 1.minute) do |request|
    if request.path.match?(CONVERSATION_API_PATH_REGEX) && read_method?(request)
      normalise_auth_header(request.get_header("HTTP_AUTHORIZATION"))
    end
  end

  throttle(Api::RateLimit::GOVUK_API_USER_WRITE_THROTTLE_NAME, limit: 500, period: 1.minute) do |request|
    if request.path.match?(CONVERSATION_API_PATH_REGEX) && !read_method?(request)
      normalise_auth_header(request.get_header("HTTP_AUTHORIZATION"))
    end
  end

  throttle(Api::RateLimit::GOVUK_END_USER_READ_THROTTLE_NAME, limit: 120, period: 1.minute) do |request|
    if request.path.match?(CONVERSATION_API_PATH_REGEX) && read_method?(request)
      request.get_header("HTTP_GOVUK_CHAT_END_USER_ID").presence
    end
  end

  throttle(Api::RateLimit::GOVUK_END_USER_WRITE_THROTTLE_NAME, limit: 20, period: 1.minute) do |request|
    if request.path.match?(CONVERSATION_API_PATH_REGEX) && !read_method?(request)
      request.get_header("HTTP_GOVUK_CHAT_END_USER_ID").presence
    end
  end

  def self.read_method?(request)
    request.get? || request.head? || request.options?
  end

  def self.normalise_auth_header(auth_header)
    return if auth_header.blank?

    auth_header.strip.gsub(/^bearer/i, "Bearer")
  end

  self.throttled_responder = lambda do |request|
    Rails.logger.info(
      "Throttled request for #{request.env['rack.attack.match_discriminator']} " \
      "for #{request.env['rack.attack.matched']}",
    )
    raise ThrottledRequest
  end
end
