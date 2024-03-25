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
end
