class SignUpController < BaseController
  skip_before_action :ensure_early_access_user_if_required
  before_action :redirect_to_homepage_if_auth_not_required
  before_action :redirect_to_homepage_if_signed_in
  before_action :ensure_sign_up_flow_position
  before_action :render_not_accepting_signups_if_sign_ups_disabled

  def user_description
    @question_config = user_research_questions_config.user_description
    @user_description_form = Form::EarlyAccess::UserDescription.new(
      choice: session.dig("sign_up", "user_description"),
    )
  end

  def confirm_user_description
    @question_config = user_research_questions_config.user_description
    @user_description_form = Form::EarlyAccess::UserDescription.new(user_description_form_params)

    if @user_description_form.valid?
      session["sign_up"]["user_description"] = @user_description_form.choice
      redirect_to sign_up_reason_for_visit_path
    else
      render :user_description, status: :unprocessable_entity
    end
  end

  def reason_for_visit
    @question_config = user_research_questions_config.reason_for_visit
    @reason_for_visit_form = Form::EarlyAccess::ReasonForVisit.new
  end

  def confirm_reason_for_visit
    if session["sign_up"]["user_description"] == "none"
      session.delete("sign_up")
      return render :sign_up_denied, status: :forbidden
    end

    @question_config = user_research_questions_config.reason_for_visit
    @reason_for_visit_form = Form::EarlyAccess::ReasonForVisit.new(reason_for_visit_form_params)

    if @reason_for_visit_form.valid?
      result = @reason_for_visit_form.submit
      session.delete("sign_up")
      if result.outcome == :early_access_user
        render :sign_up_successful
      elsif result.outcome == :waiting_list_user
        render :waitlist
      else
        render :waitlist_full
      end
    else
      render :reason_for_visit, status: :unprocessable_entity
    end
  rescue Form::EarlyAccess::ReasonForVisit::EarlyAccessUserConflictError
    render :account_already_exists, status: :conflict
  rescue Form::EarlyAccess::ReasonForVisit::WaitingListUserConflictError
    render "shared/already_on_waitlist", status: :conflict
  end

private

  def user_research_questions_config
    Rails.configuration.pilot_user_research_questions
  end

  def user_description_form_params
    params.require(:user_description_form).permit(:choice)
  end

  def reason_for_visit_form_params
    params
      .require(:reason_for_visit_form)
      .permit(:choice)
      .merge(
        email: session.dig("sign_up", "email"),
        user_description: session.dig("sign_up", "user_description"),
      )
  end

  def ensure_sign_up_flow_position
    if session.dig("sign_up", "email").blank?
      return redirect_to homepage_path
    end

    if session.dig("sign_up", "user_description").blank? && action_name.match?(/reason_for_visit/)
      redirect_to sign_up_user_description_path
    end
  end

  def sign_ups_disabled?
    !Settings.instance.sign_up_enabled
  end

  def render_not_accepting_signups_if_sign_ups_disabled
    render :not_accepting_signups, status: :forbidden if sign_ups_disabled?
  end

  def redirect_to_homepage_if_signed_in
    redirect_to homepage_path if current_early_access_user
  end

  def redirect_to_homepage_if_auth_not_required
    redirect_to homepage_path if Rails.configuration.available_without_early_access_authentication
  end
end
