class WaitingListUnsubscribeController < BaseController
  skip_before_action :ensure_early_access_user_if_required

  def unsubscribe
    return head(:ok) if request.head?

    WaitingListUser.find_by!(id: params[:id], unsubscribe_token: params[:token]).destroy!
  end
end
