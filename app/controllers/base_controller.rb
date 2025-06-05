class BaseController < ApplicationController
  before_action :ensure_signon_user_if_required
  before_action :check_chat_public_access
  helper_method :settings

private

  def check_chat_public_access
    return if settings.public_access_enabled

    expires_in(1.minute, public: true) unless Rails.env.development?
    request.session_options[:skip] = true
    response.headers["No-Fallback"] = "true"

    status = settings.downtime_type_temporary? ? :service_unavailable : :gone

    if status == :service_unavailable
      render "downtime/unavailable", status:, layout: "application"
    elsif status == :gone
      render "downtime/shutdown", status:, layout: "application"
    end
  end

  def settings
    Settings.instance
  end

  def ensure_signon_user_if_required
    return if Rails.configuration.available_without_signon_authentication

    authenticate_user!
  end

  def cache_cookieless_requests
    return if Rails.env.development?

    expires_in(1.minute, public: true)

    # a Vary of Cookie is controversial as a clients cookies can vary so much,
    # we can use it here as our CDN strips all cookies unless a session cookie
    # is available - so it effectively would only cache for cookieless requests
    response.headers["vary"] = [response.headers["vary"], "Cookie"].compact.join(", ")
  end
end
