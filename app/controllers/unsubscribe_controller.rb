class UnsubscribeController < BaseController
  skip_before_action :ensure_early_access_user_if_required
  before_action { head(:ok) if request.head? }

  def waiting_list_user
    WaitingListUser
      .find_by!(id: params[:id], unsubscribe_token: params[:token])
      .destroy!
  end

  def early_access_user
    EarlyAccessUser
      .find_by!(id: params[:id], unsubscribe_token: params[:token])
      .destroy!
  end
end
