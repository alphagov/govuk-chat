require "bcrypt"

class SessionsController < BaseController
  def confirm
    return head(:ok) if request.head?

    # if the user is already signed in just redirect to the chat page
    return redirect_to(chat_path) if current_early_access_user.present?

    artificially_slow_down_brute_force_attacks(params[:token])
    Passwordless::Session.transaction do
      passwordless_session = Passwordless::Session.lock.find_by(identifier: params[:id],
                                                                authenticatable_type: "EarlyAccessUser")

      # TODO: how should this actually behave?
      return render plain: "session not found" if passwordless_session.nil?
      # TODO: how should this actually behave? we know the user
      return render plain: "invalid token" unless passwordless_session.authenticate(params[:token])

      sign_in(passwordless_session)
      early_access_user = passwordless_session.authenticatable
      early_access_user.sign_in(passwordless_session)

      redirect_to redirect_location
    rescue EarlyAccessUser::AccessRevokedError
      sign_out_early_access_user
      # TODO: how should this actually behave?
      render plain: "access revoked"
    rescue Passwordless::Errors::TokenAlreadyClaimedError
      # TODO: how should this actually behave?
      render plain: "magic link used"
    rescue Passwordless::Errors::SessionTimedOutError
      # TODO: how should this actually behave?
      render plain: "session timed out"
    end
  end

  def destroy
    sign_out_early_access_user

    redirect_to early_access_entry_path
  end

private

  def artificially_slow_down_brute_force_attacks(token)
    return unless Passwordless.config.combat_brute_force_attacks

    # Make it "slow" on purpose to make brute-force attacks more of a hassle
    BCrypt::Password.create(token) # rubocop:disable Rails/SaveBang
  end

  def redirect_location
    # TODO: how should this actually behave?
    reset_passwordless_redirect_location!(EarlyAccessUser) || chat_path
  end
end
