class BaseController < ApplicationController
  include Passwordless::ControllerHelpers
  helper_method :current_early_access_user

private

  def current_early_access_user
    @current_early_access_user ||= authenticate_early_access_user
  end

  def authenticate_early_access_user
    user = authenticate_by_session(EarlyAccessUser)

    if user&.access_revoked?
      sign_out(EarlyAccessUser)
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
