class Rack::Attack
  self.throttled_responder = ->(_request) { raise ThrottledRequest }
end
