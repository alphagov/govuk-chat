class BaseController < ApplicationController
private

  def require_onboarding_completed
    return if session[:onboarding] == "conversation" || cookies[:conversation_id].present?

    redirect_to(onboarding_limitations_path, alert: "Confirm you understand the limitations of GOV.UK Chat before continuing.")
  end
end
