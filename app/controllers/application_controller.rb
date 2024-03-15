class ApplicationController < ActionController::Base
  before_action :login_anon

private

  def login_anon
    if session["user_id"].present? && user_param.nil?
      Current.user = AnonymousUser.new(session["user_id"])
      return
    end

    login_user(user_param || SecureRandom.uuid)
  end

  def login_user(user_id)
    session["user_id"] = user_id

    Current.user = AnonymousUser.new(user_id)
  end

  def user_param
    params[:user]
  end
end
