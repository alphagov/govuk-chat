class HomepageController < BaseController
  skip_before_action :ensure_early_access_user_if_auth_required!

  def index
    request.session_options[:skip] = true
    expires_in(5.minutes, public: true) unless Rails.env.development?
    early_access_auth = !Rails.configuration.available_without_early_access_authentication
    if early_access_auth
      @sign_in_or_up_form = Form::EarlyAccess::SignInOrUp.new
      render :index_early_access
    else
      render :index_not_early_access
    end
  end

  def sign_in_or_up
    return redirect_to homepage_path if Rails.configuration.available_without_early_access_authentication

    sign_out_early_access_user if current_early_access_user
    @sign_in_or_up_form = Form::EarlyAccess::SignInOrUp.new(sign_in_or_up_form_params)

    if @sign_in_or_up_form.valid?
      result = @sign_in_or_up_form.submit

      return render :email_sent if result.outcome == :existing_early_access_user
      return render "shared/already_on_waitlist" if result.outcome == :existing_waiting_list_user
      return render "shared/access_revoked", status: :forbidden if result.outcome == :user_revoked

      session["sign_up"] = { "email" => result.email }
      redirect_to sign_up_user_description_path
    else
      render :index_early_access, status: :unprocessable_entity
    end
  end

private

  def sign_in_or_up_form_params
    params.require(:sign_in_or_up_form).permit(:email)
  end
end
