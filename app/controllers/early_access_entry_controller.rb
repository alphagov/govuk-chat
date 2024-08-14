class EarlyAccessEntryController < BaseController
  before_action :ensure_sign_up_flow_position, except: %i[new create]

  def new
    @early_access_entry_form = Form::EarlyAccess::SignInOrUp.new
  end

  def create
    @early_access_entry_form = Form::EarlyAccess::SignInOrUp.new(sign_in_or_up_form_params)

    if @early_access_entry_form.valid?
      result = @early_access_entry_form.submit

      if result.outcome == :new_user
        session["sign_up"] = { "email" => result.email }
        redirect_to early_access_entry_user_description_path
      elsif result.outcome == :user_revoked
        render "shared/access_revoked", status: :forbidden
      else
        render :email_sent
      end
    else
      render :new, status: :unprocessable_entity
    end
  end

  def user_description
    @user_description_form = Form::EarlyAccess::UserDescription.new(
      choice: session.dig("sign_up", "user_description"),
    )
  end

  def confirm_user_description
    @user_description_form = Form::EarlyAccess::UserDescription.new(user_description_form_params)

    if @user_description_form.valid?
      session["sign_up"]["user_description"] = @user_description_form.choice
      redirect_to early_access_entry_reason_for_visit_path
    else
      render :user_description, status: :unprocessable_entity
    end
  end

  def reason_for_visit
    @reason_for_visit_form = Form::EarlyAccess::ReasonForVisit.new
  end

  def confirm_reason_for_visit
    @reason_for_visit_form = Form::EarlyAccess::ReasonForVisit.new(reason_for_visit_form_params)

    if @reason_for_visit_form.valid?
      @reason_for_visit_form.submit
      session.delete("sign_up")
      render :sign_up_successful
    else
      render :reason_for_visit, status: :unprocessable_entity
    end
  end

private

  def sign_in_or_up_form_params
    params.require(:early_access_entry_form).permit(:email)
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
      return redirect_to early_access_entry_path
    end

    if session.dig("sign_up", "user_description").blank? && action_name.match?(/reason_for_visit/)
      redirect_to early_access_entry_user_description_path
    end
  end
end
