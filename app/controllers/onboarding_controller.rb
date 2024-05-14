class OnboardingController < BaseController
  def limitations; end

  def limitations_confirm
    session[:onboarding] = "privacy"
    redirect_to onboarding_privacy_path
  end

  def privacy; end

  def privacy_confirm
    session[:onboarding] = "conversation"

    if cookies[:conversation_id]
      redirect_to show_conversation_path(cookies[:conversation_id])
    else
      redirect_to new_conversation_path
    end
  end
end
