require "bcrypt"

class SessionsController < BaseController
  def confirm
    return head(:ok) if request.head?

    # if the user is already signed in just redirect to the chat page
    return redirect_to(chat_path) if current_early_access_user.present?

    artificially_slow_down_brute_force_attacks(params[:token])
    passwordless_session = Passwordless::Session.find_by(identifier: params[:id],
                                                         authenticatable_type: "EarlyAccessUser")

    # TODO: how should this actually behave?
    return render plain: "session not found" if passwordless_session.nil?
    # TODO: how should this actually behave? we know the user
    return render plain: "invalid token" unless passwordless_session.authenticate(params[:token])

    Passwordless::Session.transaction do
      sign_in(passwordless_session)
      early_access_user = passwordless_session.authenticatable
      early_access_user.sign_in(passwordless_session)
      # rescue EarlyAccessUser::AbortSignInError
      #   sign_out(EarlyAccessUser)
      #   # TODO how should this actually behave?
      #   return render plain: "sign in failed"
    end
    redirect_to redirect_location
  rescue Passwordless::Errors::TokenAlreadyClaimedError
    # TODO: how should this actually behave?
    render plain: "magic link used"
  rescue Passwordless::Errors::SessionTimedOutError
    # TODO: how should this actually behave?
    redirect_to action: :timeout
  end

  def destroy
    sign_out(EarlyAccessUser)

    # TODO: expect we want to customise this redirect and flash
    redirect_to(
      early_access_entry_path,
      notice: I18n.t("passwordless.sessions.destroy.signed_out"),
    )
  end

  def timeout; end

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
