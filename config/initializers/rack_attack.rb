require "api/rate_limit"
require "api/rate_limit/middleware"
require "api/auth_middleware"

Rails.application.config.middleware.insert_after ActionDispatch::Executor, Api::RateLimit::Middleware
Rails.application.config.middleware.insert_before Rack::Attack, Api::AuthMiddleware

class Rack::Attack
  CONVERSATION_API_PATH_REGEX = /^\/api\/v\d+\/conversation/

  throttle(Api::RateLimit::GOVUK_API_USER_READ_THROTTLE_NAME, limit: 2_400, period: 1.minute) do |request|
    if request.path.match?(CONVERSATION_API_PATH_REGEX) && read_method?(request)
      signon_uid(request)
    end
  end

  throttle(Api::RateLimit::GOVUK_API_USER_WRITE_THROTTLE_NAME, limit: 200, period: 1.minute) do |request|
    if request.path.match?(CONVERSATION_API_PATH_REGEX) && !read_method?(request)
      signon_uid(request)
    end
  end

  throttle(Api::RateLimit::GOVUK_END_USER_READ_THROTTLE_NAME, limit: 180, period: 1.minute) do |request|
    if request.path.match?(CONVERSATION_API_PATH_REGEX) && read_method?(request)
      user_id = end_user_id(request)

      next if user_id.nil?

      "#{signon_uid(request)}-#{user_id}"
    end
  end

  throttle(Api::RateLimit::GOVUK_END_USER_WRITE_THROTTLE_NAME, limit: 15, period: 1.minute) do |request|
    if request.path.match?(CONVERSATION_API_PATH_REGEX) && !read_method?(request)
      user_id = end_user_id(request)

      next if user_id.nil?

      "#{signon_uid(request)}-#{user_id}"
    end
  end

  def self.read_method?(request)
    request.get? || request.head? || request.options?
  end

  def self.signon_uid(request)
    user = request.env.fetch("warden").user
    raise "No warden user available" unless user
    raise "Missing uid for user #{user.id}" unless user.uid

    "signon:#{user.uid}"
  end

  def self.end_user_id(request)
    request.get_header("HTTP_GOVUK_CHAT_END_USER_ID").presence
  end

  self.throttled_responder = lambda do |request|
    Rails.logger.info(
      "Throttled request for #{request.env['rack.attack.match_discriminator']} " \
      "for #{request.env['rack.attack.matched']}",
    )
    raise ThrottledRequest
  end
end
