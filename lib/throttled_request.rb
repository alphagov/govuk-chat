# Exception to be used when Rack::Attack throttles a user request
class ThrottledRequest < RuntimeError; end
