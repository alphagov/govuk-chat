class EarlyAccessController < ApplicationController
  include Passwordless::ControllerHelpers
  helper_method :current_user

private

  def current_user
    @current_user ||= authenticate_by_session(EarlyAccessUser)
  end

  def require_user!
    return if current_user

    save_passwordless_redirect_location!(EarlyAccessUser)
    redirect_to early_access_entry_path
  end
end
