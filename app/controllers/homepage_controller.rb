class HomepageController < BaseController
  skip_before_action :ensure_early_access_user_if_required
  skip_forgery_protection # as we cache the form we can't verify the token
  before_action(only: :index) do
    expires_in(1.minute, public: true) unless current_early_access_user.present? || Rails.env.development?
    add_cookie_to_vary_header
  end

  def index
    early_access_auth = !Rails.configuration.available_without_early_access_authentication

    if current_early_access_user.present?
      render :index_signed_in
    elsif early_access_auth
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

      case result.outcome
      when :existing_early_access_user
        render :email_sent
      when :existing_waiting_list_user
        render "shared/already_on_waitlist"
      when :user_revoked
        render "shared/access_revoked", status: :forbidden
      when :magic_link_limit
        render :magic_link_limit, status: :too_many_requests
      else
        session["sign_up"] = {
          "email" => result.email,
          "previous_sign_up_denied" => session["sign_up_denied"].present?,
        }
        redirect_to sign_up_user_description_path
      end
    else
      render :index_early_access, status: :unprocessable_entity
    end
  end

private

  def sign_in_or_up_form_params
    params.require(:sign_in_or_up_form).permit(:email)
  end
end
