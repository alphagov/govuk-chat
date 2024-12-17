class BaseController < ApplicationController
  include Passwordless::ControllerHelpers
  before_action :check_chat_public_access
  before_action :ensure_signon_user_if_required
  before_action :ensure_early_access_user_if_required
  helper_method :current_early_access_user, :settings

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

  def current_early_access_user
    return unless settings.public_access_enabled

    @current_early_access_user ||= authenticate_early_access_user
  end

  def sign_out_early_access_user
    sign_out(EarlyAccessUser)
    @current_early_access_user = nil
  end

  def authenticate_early_access_user
    user = authenticate_by_session(EarlyAccessUser)

    if user&.revoked?
      sign_out_early_access_user
      nil
    else
      user
    end
  end

  def require_early_access_user!
    return if current_early_access_user

    respond_to do |format|
      format.html { redirect_to homepage_path }
      format.json { render json: { error: "User not authenticated" }, status: :bad_request }
    end
  end

  def ensure_early_access_user_if_required
    return if Rails.configuration.available_without_early_access_authentication

    require_early_access_user!
  end

  def ensure_signon_user_if_required
    return if Rails.configuration.available_without_signon_authentication

    authenticate_user!
  end

  def cache_if_not_logged_in
    return if Rails.env.development? || current_early_access_user

    expires_in(1.minute, public: true)

    # a Vary of Cookie is controversial as a clients cookies can vary so much,
    # we can use it here as our CDN strips all cookies unless a session cookie
    # is available - so it effectively would only cache for cookieless requests
    response.headers["vary"] = [response.headers["vary"], "Cookie"].compact.join(", ")
  end
end
