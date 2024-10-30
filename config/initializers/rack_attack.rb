class Rack::Attack
  throttle("sign-in or sign-ups by IP", limit: 10, period: 5.minutes) do |request|
    homepage_path = Rails.application.routes.url_helpers.homepage_path
    next request.ip if request.path == homepage_path && request.post?
  end

  self.throttled_responder = lambda do |request|
    Rails.logger.info(
      "Throttled request for #{request.env['rack.attack.match_discriminator']} " \
      "for #{request.env['rack.attack.matched']}",
    )
    raise ThrottledRequest
  end
end
