class WaitingListUnsubscribeController < BaseController
  skip_before_action :ensure_early_access_user_if_auth_required!
  before_action :load_waiting_list_user

  def unsubscribe; end

  def unsubscribe_confirm
    @user.destroy!
  end

private

  def load_waiting_list_user
    @user = WaitingListUser.find_by!(id: params[:id], unsubscribe_token: params[:token])
  end
end
