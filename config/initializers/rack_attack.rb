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

  throttle(Api::RateLimit::GOVUK_CLIENT_DEVICE_READ_THROTTLE_NAME, limit: 120, period: 1.minute) do |request|
    if request.path.match?(CONVERSATION_API_PATH_REGEX) && read_method?(request)
      request.get_header("HTTP_GOVUK_CHAT_CLIENT_DEVICE_ID").presence
    end
  end

  throttle(Api::RateLimit::GOVUK_CLIENT_DEVICE_WRITE_THROTTLE_NAME, limit: 20, period: 1.minute) do |request|
    if request.path.match?(CONVERSATION_API_PATH_REGEX) && !read_method?(request)
      request.get_header("HTTP_GOVUK_CHAT_CLIENT_DEVICE_ID").presence
    end
  end

  def self.rails_controller_action(url)
    route = Rails.application.routes.recognize_path(url)

    "#{route[:controller]}##{route[:action]}"
  rescue StandardError
    nil
  end

  def self.cdn_client_ip(request)
    # We use a header set by the CDN to specify which IP address to use a
    # discriminiator. We can't use request.ip as that uses the IP address of
    # the CDN - so risks blocking the CDN rather than the end user.
    request.get_header("HTTP_TRUE_CLIENT_IP")
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
