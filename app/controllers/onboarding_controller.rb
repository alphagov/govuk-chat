class OnboardingController < BaseController
  before_action :ensure_onboarding_flow_position

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

private

  def ensure_onboarding_flow_position
    return redirect_to show_conversation_path(cookies[:conversation_id]) if cookies[:conversation_id]
    return redirect_to new_conversation_path if session[:onboarding] == "conversation"

    if session[:onboarding] == "privacy" && !action_name.match?(/privacy/)
      return redirect_to onboarding_privacy_path
    end

    if %w[privacy conversation].exclude?(session[:onboarding]) && !action_name.match?(/limitations/)
      redirect_to onboarding_limitations_path
    end
  end
end
