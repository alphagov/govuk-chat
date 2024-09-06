class EarlyAccessUnsubscribeController < BaseController
  skip_before_action :ensure_early_access_user_if_required

  def unsubscribe
    @token = params[:token]
    id = params[:id]
    user = EarlyAccessUser.find_by!(id:, unsubscribe_access_token: @token)
    user.destroy!
  end
end
