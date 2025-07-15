class Api::AuthMiddleware
  def initialize(app)
    @app = app
  end

  def call(env)
    path = env["PATH_INFO"].to_s

    if path.start_with?("/api/")
      GDS::SSO.authenticate_user!(env.fetch("warden"))
    end

    @app.call(env)
  end
end
