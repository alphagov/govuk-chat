require "bcrypt"

class SessionsController < BaseController
  def confirm
    return head(:ok) if request.head?

    return redirect_to(show_conversation_path) if current_early_access_user.present?

    artificially_slow_down_brute_force_attacks(params[:token])
    Passwordless::Session.transaction do
      passwordless_session = Passwordless::Session.lock.find_by(identifier: params[:id],
                                                                authenticatable_type: "EarlyAccessUser")

      if passwordless_session.nil? || !passwordless_session.authenticate(params[:token])
        return render :link_expired, status: :not_found
      end

      sign_in(passwordless_session)
      early_access_user = passwordless_session.authenticatable
      early_access_user.sign_in(passwordless_session)

      redirect_to redirect_location
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

    redirect_to early_access_entry_sign_in_or_up_path
  end

private

  def artificially_slow_down_brute_force_attacks(token)
    return unless Passwordless.config.combat_brute_force_attacks

    # Make it "slow" on purpose to make brute-force attacks more of a hassle
    BCrypt::Password.create(token) # rubocop:disable Rails/SaveBang
  end

  def redirect_location
    reset_passwordless_redirect_location!(EarlyAccessUser) || onboarding_limitations_path
  end
end
