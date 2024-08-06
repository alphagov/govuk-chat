class SigninController < ApplicationController
  include Passwordless::ControllerHelpers
  layout "application"

  def new
    @signin_form = Form::SigninUser.new
  end

  def create
    @signin_form = Form::SigninUser.new(signin_attributes)
    if @signin_form.submit
      redirect_to sign_in_email_sent_path
    end
  end

  def confirm
    # Some email clients will visit links in emails to check if they are
    # safe. We don't want to sign in the user in that case.
    return head(:ok) if request.head?

    if passwordless_session&.authenticate(params[:token])
      sign_in(passwordless_session)
      redirect_to(redirect_location)
    else
      redirect_to(sign_in_failure_path)
    end
  end

  def destroy
    sign_out(EarlyAccessUser)
    redirect_to chat_path
  end

  def failure; end

private

  def passwordless_session
    @passwordless_session ||= Passwordless::Session.find_by!(
      identifier: params[:id],
      authenticatable_type: "EarlyAccessUser",
    )
  end

  def signin_attributes
    params.require(:form_signin_user).permit(:email)
  end

  def redirect_location
    reset_passwordless_redirect_location!(EarlyAccessUser) || show_conversation_path
  end
end
