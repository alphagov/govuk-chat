class ApplicationController < ActionController::Base
  before_action :login_anon

  if ENV["BASIC_AUTH_USERNAME"]
    http_basic_authenticate_with(
      name: ENV.fetch("BASIC_AUTH_USERNAME"),
      password: ENV.fetch("BASIC_AUTH_PASSWORD"),
    )
  end

private

  def login_anon
    if session["user_id"].present? && params[:user_id].nil?
      Current.user = AnonymousUser.new(session["user_id"])
      return
    end

    login_user(params[:user_id] || SecureRandom.uuid)
  end

  def login_user(user_id)
    session["user_id"] = user_id

    Current.user = AnonymousUser.new(user_id)
  end

  def require_chat_risks_understood
    return if session[:chat_risks_understood]

    # truncated to avoid exhausting session capacity with an aspect of user input
    session[:referrer] = request.original_url.truncate(255, omission: "")
    redirect_to(chat_onboarding_path, alert: "Check the checkbox to show you understand the guidance")
  end
end
