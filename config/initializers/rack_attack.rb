class Rack::Attack
  CONVERSATION_API_PATH_REGEX = /^\/api\/v\d+\/conversation/
  TOKEN_READ_THROTTLE_NAME = "read requests to Conversations API with token".freeze
  TOKEN_WRITE_THROTTLE_NAME = "write method requests to Conversations API with token".freeze
  DEVICE_READ_THROTTLE_NAME = "read requests to Conversations API with device id".freeze
  DEVICE_WRITE_THROTTLE_NAME = "write requests to Conversations API with device id".freeze

  class RateLimitHeadersMiddleware
    THROTTLE_TO_PREFIX_MAPPING = {
      TOKEN_READ_THROTTLE_NAME => "Token-Read",
      TOKEN_WRITE_THROTTLE_NAME => "Token-Write",
      DEVICE_READ_THROTTLE_NAME => "Device-Id-Read",
      DEVICE_WRITE_THROTTLE_NAME => "Device-Id-Write",
    }.freeze

    def initialize(app)
      @app = app
    end

    def call(env)
      status, headers, body = @app.call(env)
      throttle_data = env["rack.attack.throttle_data"]

      if throttle_data
        throttle_data.each do |throttle_name, throttle_info|
          header_name_prefix = THROTTLE_TO_PREFIX_MAPPING[throttle_name]
          limit = throttle_info[:limit]
          count = throttle_info[:count]
          period = throttle_info[:period]
          first_request_in_period = throttle_info[:epoch_time]
          seconds_until_reset = (first_request_in_period + period) - Time.current.to_i

          headers["#{header_name_prefix}-RateLimit-Limit"] = limit.to_s
          headers["#{header_name_prefix}-RateLimit-Remaining"] = [limit - count, 0].max.to_s
          headers["#{header_name_prefix}-RateLimit-Reset"] = "#{seconds_until_reset}s"
        end
      end

      [status, headers, body]
    end
  end

  Rails.application.config.middleware.insert_after ActionDispatch::Executor, RateLimitHeadersMiddleware

  throttle("sign-in or sign-ups by IP", limit: 10, period: 5.minutes) do |request|
    homepage_path = Rails.application.routes.url_helpers.homepage_path
    next cdn_client_ip(request) if request.path == homepage_path && request.post?
  end

  throttle("sign-up final step by IP", limit: 10, period: 5.minutes) do |request|
    sign_up_path = Rails.application.routes.url_helpers.sign_up_found_chat_path
    next cdn_client_ip(request) if request.path == sign_up_path && request.post?
  end

  throttle("sign-in token attempts", limit: 20, period: 5.minutes) do |request|
    if rails_controller_action(request.url) == "sessions#confirm" && request.get?
      cdn_client_ip(request)
    end
  end

  throttle("early access user unsubscribe attempts", limit: 20, period: 5.minutes) do |request|
    if rails_controller_action(request.url) == "unsubscribe#early_access_user" && request.get?
      cdn_client_ip(request)
    end
  end

  throttle("waiting list user unsubscribe attempts", limit: 20, period: 5.minutes) do |request|
    if rails_controller_action(request.url) == "unsubscribe#waiting_list_user" && request.get?
      cdn_client_ip(request)
    end
  end

  throttle(TOKEN_READ_THROTTLE_NAME, limit: 10_000, period: 1.minute) do |request|
    if request.path.match?(CONVERSATION_API_PATH_REGEX) && read_method?(request)
      normalise_auth_header(request.get_header("HTTP_AUTHORIZATION"))
    end
  end

  throttle(TOKEN_WRITE_THROTTLE_NAME, limit: 500, period: 1.minute) do |request|
    if request.path.match?(CONVERSATION_API_PATH_REGEX) && !read_method?(request)
      normalise_auth_header(request.get_header("HTTP_AUTHORIZATION"))
    end
  end

  throttle(DEVICE_READ_THROTTLE_NAME, limit: 120, period: 1.minute) do |request|
    if request.path.match?(CONVERSATION_API_PATH_REGEX) && read_method?(request)
      request.get_header("HTTP_GOVUK_CHAT_CLIENT_DEVICE_ID").presence
    end
  end

  throttle(DEVICE_WRITE_THROTTLE_NAME, limit: 20, period: 1.minute) do |request|
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
