class EarlyAccessUnsubscribeController < BaseController
  skip_before_action :ensure_early_access_user_if_auth_required!

  def revoke
    @token = params[:token]
    user = EarlyAccessUser.find_by!(revoke_access_token: @token)

    redirect_to homepage_path if user.nil?
  end

  def revoke_confirm
    EarlyAccessUser
      .find_by(revoke_access_token: params[:token])&.destroy!

    redirect_to homepage_path
  end
end
