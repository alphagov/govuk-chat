class Rack::Attack
  CONVERSATION_API_PATH_REGEX = /^\/api\/v\d+\/conversation/
  BEARER_TOKEN_REGEX = /^Bearer (.+)$/

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

  throttle("get requests to Conversations API", limit: 1000, period: 1.minute) do |request|
    if request.path.match?(CONVERSATION_API_PATH_REGEX) && read_method?(request)
      request.ip
    end
  end

  throttle("all other http method requests to Conversations API", limit: 150, period: 1.minute) do |request|
    if request.path.match?(CONVERSATION_API_PATH_REGEX) && !read_method?(request)
      request.ip
    end
  end

  # Other options for throttling
  ## Throttle by auth token
  throttle("get requests to Conversations API with token", limit: 5000, period: 1.minute) do |request|
    if request.path.match?(CONVERSATION_API_PATH_REGEX) && read_method?(request)
      auth_header = request.env["HTTP_AUTHORIZATION"]
      token = auth_header.to_s.match(BEARER_TOKEN_REGEX)&.captures&.first
      token.presence
    end
  end

  throttle("all other http method requests to Conversations API with token", limit: 200, period: 1.minute) do |request|
    if request.path.match?(CONVERSATION_API_PATH_REGEX) && !read_method?(request)
      auth_header = request.env["HTTP_AUTHORIZATION"]
      token = auth_header.to_s.match(BEARER_TOKEN_REGEX)&.captures&.first
      token.presence
    end
  end

  ## Throttle by device ID - the app team would have to pass this to us in the header
  throttle("get requests to Conversations API with device id", limit: 120, period: 1.minute) do |request|
    if request.path.match?(CONVERSATION_API_PATH_REGEX) && read_method?(request)
      request.get_header("HTTP_GOVUK_CHAT_CLIENT_DEVICE_ID").presence
    end
  end

  throttle("all other http method requests to Conversations API with device id", limit: 20, period: 1.minute) do |request|
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

  self.throttled_responder = lambda do |request|
    Rails.logger.info(
      "Throttled request for #{request.env['rack.attack.match_discriminator']} " \
      "for #{request.env['rack.attack.matched']}",
    )
    raise ThrottledRequest
  end
end
