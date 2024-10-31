class Rack::Attack
  throttle("sign-in or sign-ups by IP", limit: 10, period: 5.minutes) do |request|
    homepage_path = Rails.application.routes.url_helpers.homepage_path
    next cdn_client_ip(request) if request.path == homepage_path && request.post?
  end

  throttle("sign-up final step by IP", limit: 10, period: 5.minutes) do |request|
    sign_up_path = Rails.application.routes.url_helpers.sign_up_found_chat_path
    next cdn_client_ip(request) if request.path == sign_up_path && request.post?
  end

  def self.cdn_client_ip(request)
    # We use a header set by the CDN to specify which IP address to use a
    # discriminiator. We can't use request.ip as that uses the IP address of
    # the CDN - so risks blocking the CDN rather than the end user.
    request.get_header("HTTP_TRUE_CLIENT_IP")
  end

  self.throttled_responder = lambda do |request|
    Rails.logger.info(
      "Throttled request for #{request.env['rack.attack.match_discriminator']} " \
      "for #{request.env['rack.attack.matched']}",
    )
    raise ThrottledRequest
  end
end
