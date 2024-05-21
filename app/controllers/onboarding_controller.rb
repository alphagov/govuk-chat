class OnboardingController < BaseController
  layout "conversation"
  before_action :ensure_onboarding_flow_position

  def limitations
    session[:onboarding] = nil
    session[:more_information] = true if params[:more_information].present?
    @more_information = session[:more_information].present?
  end

  def limitations_confirm
    session[:onboarding] = "privacy"
    redirect_to onboarding_privacy_path
  end

  def privacy; end

  def privacy_confirm
    session[:onboarding] = "conversation"
    redirect_to show_conversation_path
  end

private

  def ensure_onboarding_flow_position
    if cookies[:conversation_id].present? || session[:onboarding] == "conversation"
      return redirect_to show_conversation_path
    end

    if session[:onboarding] == "privacy" && !action_name.match?(/privacy/)
      return redirect_to onboarding_privacy_path
    end

    if %w[privacy conversation].exclude?(session[:onboarding]) && !action_name.match?(/limitations/)
      redirect_to onboarding_limitations_path
    end
  end
end
