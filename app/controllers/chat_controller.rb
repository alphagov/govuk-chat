class ChatController < BaseController
  def index
    expires_in(5.minutes, public: true) unless Rails.env.development?
  end

  def onboarding_limitations; end

  def onboarding_limitations_confirm
    session[:onboarding] = "privacy"
    redirect_to onboarding_privacy_path
  end

  def onboarding_privacy; end

  def onboarding_privacy_confirm
    session[:onboarding] = "conversation"

    if cookies[:conversation_id]
      redirect_to show_conversation_path(cookies[:conversation_id])
    else
      redirect_to new_conversation_path
    end
  end
end
