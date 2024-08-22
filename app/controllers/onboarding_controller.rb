class OnboardingController < BaseController
  layout "conversation"
  before_action :ensure_onboarding_flow_position

  def limitations
    session[:onboarding] = nil
    @more_information = session[:more_information].present?
    @conversation_data_attributes = { module: "onboarding" }
    @title = if @more_information
               "More information on GOV.UK Chat and its limitations"
             else
               "Introduction to GOV.UK Chat and its limitations"
             end

    respond_to do |format|
      format.html { render :limitations }
      format.json do
        if @more_information
          render json: {
            title: @title,
            conversation_data: @conversation_data_attributes,
            conversation_append_html: render_to_string(partial: "tell_me_more_messages",
                                                       formats: :html),
            form_html: render_to_string(partial: "limitations_form",
                                        formats: :html,
                                        locals: {
                                          more_information: true,
                                        }),
          }
        else
          render json: {}, status: :not_acceptable
        end
      end
    end
  end

  def limitations_confirm
    if params[:more_information].present?
      session[:more_information] = true
      redirect_to onboarding_limitations_path(anchor: "tell-me-more")
    else
      session[:onboarding] = "privacy"
      redirect_to onboarding_privacy_path(anchor: "i-understand")
    end
  end

  def privacy
    @more_information = session[:more_information].present?
    @conversation_data_attributes = { module: "onboarding" }
    @title = "Privacy on GOV.UK Chat"

    respond_to do |format|
      format.html { render :privacy }
      format.json do
        render json: {
          title: @title,
          conversation_data: @conversation_data_attributes,
          conversation_append_html: render_to_string(partial: "privacy_messages",
                                                     formats: :html),
          form_html: render_to_string(partial: "privacy_form",
                                      formats: :html),
        }
      end
    end
  end

  def privacy_confirm
    session[:onboarding] = "conversation"
    current_early_access_user.update!(onboarding_completed: true) if current_early_access_user
    redirect_to show_conversation_path(anchor: "start-chatting")
  end

private

  def ensure_onboarding_flow_position
    if cookies[:conversation_id].present? ||
        session[:onboarding] == "conversation" ||
        current_early_access_user&.onboarding_completed

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
