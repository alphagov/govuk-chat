class EarlyAccessController < ApplicationController
  include Passwordless::ControllerHelpers
  helper_method :current_early_access_user

private

  def current_early_access_user
    @current_early_access_user ||= authenticate_by_session(EarlyAccessUser)
  end

  def require_early_access_user!
    return if current_early_access_user

    save_passwordless_redirect_location!(EarlyAccessUser)
    redirect_to early_access_entry_path
  end
end
