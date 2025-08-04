class PathNormaliserMiddleware
  def initialize(app)
    @app = app
  end

  # This middleware is used to change the Rack env["PATH_INFO"] to be the same
  # path that Rails will normalise the path to for routing. This allows middleware
  # after this has run and the Rails app itself to have a consistent path.
  def call(env)
    env["PATH_INFO"] = ::ActionDispatch::Journey::Router::Utils.normalize_path(env["PATH_INFO"].to_s)

    @app.call(env)
  end
end
