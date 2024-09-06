class EarlyAccessUnsubscribeController < BaseController
  skip_before_action :ensure_early_access_user_if_auth_required!

  def unsubscribe
    @token = params[:token]
    id = params[:id]
    user = EarlyAccessUser.find_by!(id:, revoke_access_token: @token)
    user.destroy!
  end
end
