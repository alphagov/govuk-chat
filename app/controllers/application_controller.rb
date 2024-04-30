class ApplicationController < ActionController::Base
  include GDS::SSO::ControllerMethods
  before_action :set_current

  if ENV["BASIC_AUTH_USERNAME"]
    http_basic_authenticate_with(
      name: ENV.fetch("BASIC_AUTH_USERNAME"),
      password: ENV.fetch("BASIC_AUTH_PASSWORD"),
    )
  end

private

  def set_current
    Current.user = current_user
  end

  def require_chat_risks_understood
    return if session[:chat_risks_understood]

    # truncated to avoid exhausting session capacity with an aspect of user input
    session[:referrer] = request.original_url.truncate(255, omission: "")
    redirect_to(chat_onboarding_path, alert: "Check the checkbox to show you understand the guidance")
  end
end
