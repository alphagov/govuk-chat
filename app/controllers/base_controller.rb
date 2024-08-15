class BaseController < ApplicationController
  include Passwordless::ControllerHelpers
  before_action :check_chat_public_access
  helper_method :current_early_access_user, :settings

private

  def check_chat_public_access
    return if settings.public_access_enabled

    expires_in(1.minute, public: true) unless Rails.env.development?
    request.session_options[:skip] = true

    status = settings.downtime_type_temporary? ? :service_unavailable : :gone
    render "downtime/unavailable", status:, layout: "application"
  end

  def settings
    Settings.instance
  end

  def current_early_access_user
    @current_early_access_user ||= authenticate_early_access_user
  end

  def sign_out_early_access_user
    sign_out(EarlyAccessUser)
    @current_early_access_user = nil
  end

  def authenticate_early_access_user
    user = authenticate_by_session(EarlyAccessUser)

    if user&.access_revoked?
      sign_out_early_access_user
      nil
    else
      user
    end
  end

  def require_early_access_user!
    return if current_early_access_user

    save_passwordless_redirect_location!(EarlyAccessUser)
    redirect_to early_access_entry_path
  end

  def require_onboarding_completed
    return if session[:onboarding] == "conversation" || cookies[:conversation_id].present?

    redirect_to onboarding_limitations_path
  end
end
