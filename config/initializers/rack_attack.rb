require "api/rate_limit"
require "api/rate_limit/middleware"
require "api/auth_middleware"

Rails.application.config.middleware.insert_after ActionDispatch::Executor, Api::RateLimit::Middleware
Rails.application.config.middleware.insert_before Rack::Attack, Api::AuthMiddleware

class Rack::Attack
  throttle(Api::RateLimit::GOVUK_API_USER_DEFAULT_THROTTLE_NAME, limit: 10_800, period: 1.minute) do |request|
    signon_uid(request) if Api::RateLimit.default?(request)
  end

  throttle(Api::RateLimit::GOVUK_API_USER_CONVERSATION_WRITE_THROTTLE_NAME, limit: 900, period: 1.minute) do |request|
    signon_uid(request) if Api::RateLimit.conversation_write?(request)
  end

  throttle(Api::RateLimit::GOVUK_END_USER_DEFAULT_THROTTLE_NAME, limit: 180, period: 1.minute) do |request|
    if Api::RateLimit.default?(request)
      user_id = end_user_id(request)

      next if user_id.nil?

      "#{signon_uid(request)}-#{user_id}"
    end
  end

  throttle(Api::RateLimit::GOVUK_END_USER_CONVERSATION_WRITE_THROTTLE_NAME, limit: 15, period: 1.minute) do |request|
    if Api::RateLimit.conversation_write?(request)
      user_id = end_user_id(request)

      next if user_id.nil?

      "#{signon_uid(request)}-#{user_id}"
    end
  end

  def self.signon_uid(request)
    user = request.env.fetch("warden").user
    raise "No warden user available" unless user
    raise "Missing uid for user #{user.id}" unless user.uid

    "signon:#{user.uid}"
  end

  def self.end_user_id(request)
    request.get_header("HTTP_GOVUK_CHAT_END_USER_ID")&.strip.presence
  end

  self.throttled_responder = lambda do |request|
    Rails.logger.info(
      "Throttled request for #{request.env['rack.attack.match_discriminator']} " \
      "for #{request.env['rack.attack.matched']}",
    )
    raise ThrottledRequest
  end
end
