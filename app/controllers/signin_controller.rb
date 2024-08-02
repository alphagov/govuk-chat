class SigninController < ActionController::Base # rubocop:disable Rails/ApplicationController
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

  def confirm; end

private

  def signin_attributes
    params.require(:form_signin_user).permit(:email)
  end
end
