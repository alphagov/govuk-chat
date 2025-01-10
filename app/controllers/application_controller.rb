class ApplicationController < ActionController::Base
  include GDS::SSO::ControllerMethods

  # Basic authentication
  #
  # We support multiple logins via basic auth. The pairs of credentials can
  # be configured with BASIC_AUTH_USERNAME* and BASIC_AUTH_PASSWORD* env vars.
  #
  # To have multiple basic auth logins we can set suffixes on the env vars:
  # - BASIC_AUTH_USERNAME_USER_1=user_1
  # - BASIC_AUTH_PASSWORD_USER_1=password_1
  # - BASIC_AUTH_USERNAME_USER_2=user_2
  # - BASIC_AUTH_PASSWORD_USER_2=password_2
  #
  # If we just want one basic auth credential we can skip the suffix:
  # - BASIC_AUTH_USERNAME=user
  # - BASIC_AUTH_PASSWORD=password
  before_action do
    next unless ENV.keys.any? { |k| k.starts_with?("BASIC_AUTH_USERNAME") }

    authenticate_or_request_with_http_basic do |given_username, given_password|
      username_env_vars = ENV.keys.select { |key| key.starts_with?("BASIC_AUTH_USERNAME") }
      credentials = username_env_vars.map do |username_env_var|
        password_env_var = username_env_var.sub(/^BASIC_AUTH_USERNAME/, "BASIC_AUTH_PASSWORD")
        [ENV.fetch(username_env_var), ENV.fetch(password_env_var)]
      end

      credentials.any? do |(username, password)|
        # Using & to avoid short circuiting as per:
        # https://github.com/rails/rails/blob/86312f5dc05b96d9c1c71ef03d257c155622f00e/actionpack/lib/action_controller/metal/http_authentication.rb#L88-L91
        ActiveSupport::SecurityUtils.secure_compare(given_username, username) &
          ActiveSupport::SecurityUtils.secure_compare(given_password, password)
      end
    end
  end
end
