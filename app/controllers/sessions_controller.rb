require "bcrypt"

class SessionsController < BaseController
  skip_before_action :ensure_early_access_user_if_required

  def confirm
    return head(:ok) if request.head?

    return redirect_to(show_conversation_path) if current_early_access_user.present?

    artificially_slow_down_brute_force_attacks(params[:token])
    Passwordless::Session.transaction do
      passwordless_session = Passwordless::Session.lock.find_by(identifier: params[:id],
                                                                authenticatable_type: "EarlyAccessUser")

      if passwordless_session.nil? ||
          !passwordless_session.authenticatable ||
          !passwordless_session.authenticate(params[:token])
        return render :link_expired, status: :not_found
      end

      sign_in(passwordless_session)
      early_access_user = passwordless_session.authenticatable
      early_access_user.sign_in(passwordless_session)
      configure_session_and_conversation_cookie(early_access_user)

      if cookies[:conversation_id].present?
        render :resume_conversation_choice
      else
        redirect_to onboarding_limitations_path
      end
    rescue EarlyAccessUser::AccessRevokedError
      sign_out_early_access_user
      render "shared/access_revoked", status: :forbidden
    rescue Passwordless::Errors::TokenAlreadyClaimedError
      render :link_expired, status: :conflict
    rescue Passwordless::Errors::SessionTimedOutError
      render :link_expired, status: :gone
    end
  end

  def destroy
    sign_out_early_access_user
  end

private

  def artificially_slow_down_brute_force_attacks(token)
    return unless Passwordless.config.combat_brute_force_attacks

    # Make it "slow" on purpose to make brute-force attacks more of a hassle
    BCrypt::Password.create(token) # rubocop:disable Rails/SaveBang
  end

  def configure_session_and_conversation_cookie(early_access_user)
    cookies.delete(:conversation_id) if cookies[:conversation_id].present?
    session[:onboarding] = "conversation" if early_access_user.onboarding_completed
    cookies[:conversation_id] = Conversation
                                  .active
                                  .where(user: early_access_user)
                                  .order(created_at: :desc)
                                  .pick(:id)
  end
end
