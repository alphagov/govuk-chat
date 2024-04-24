class BaseController < ApplicationController
private

  def require_chat_risks_understood
    return if session[:chat_risks_understood]

    # truncated to avoid exhausting session capacity with an aspect of user input
    session[:referrer] = request.original_url.truncate(255, omission: "")
    redirect_to(chat_onboarding_path, alert: "Check the checkbox to show you understand the guidance")
  end
end
