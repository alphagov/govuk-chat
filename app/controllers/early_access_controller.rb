class EarlyAccessController < ActionController::Base # rubocop:disable Rails/ApplicationController
  include Passwordless::ControllerHelpers
  helper_method :current_user
  before_action :require_user!

  layout "application"

private

  def current_user
    @current_user ||= authenticate_by_session(EarlyAccessUser)
  end

  def require_user!
    return if current_user

    save_passwordless_redirect_location!(EarlyAccessUser)
    redirect_to sign_in_path
  end
end
