class BaseController < ApplicationController
  before_action :ensure_signon_user_if_required
  before_action :authorise_web_user
  before_action :check_chat_web_access
  helper_method :settings

private

  def check_chat_web_access
    return if settings.web_access_enabled

    expires_in(1.minute, public: true) unless Rails.env.development?
    request.session_options[:skip] = true
    response.headers["No-Fallback"] = "true"

    render "downtime/unavailable", status: :service_unavailable, layout: "application"
  end

  def settings
    Settings.instance
  end

  def ensure_signon_user_if_required
    return if Rails.configuration.available_without_signon_authentication

    authenticate_user!
  end

  def authorise_web_user
    authorise_user!(SignonUser::Permissions::WEB_CHAT)
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
