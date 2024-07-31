class SignupController < EarlyAccessController
  include Passwordless::ControllerHelpers
  def new
    @user = EarlyAccessUser.new
  end

  def create
    @user = EarlyAccessUser.new(user_params)
    @user.save!
    sign_in(create_passwordless_session(@user))
  end

private

  def user_params
    params.require(:early_access_user).permit(:email)
  end
end
