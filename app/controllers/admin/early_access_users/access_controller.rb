class Admin::EarlyAccessUsers::AccessController < Admin::BaseController
  before_action :find_user
  before_action :redirect_to_user_show_page_if_already_revoked, only: %i[revoke revoke_confirm]
  before_action :redirect_to_user_show_page_unless_revoked_or_banned, only: %i[restore]

  def revoke
    @form = Admin::Form::EarlyAccessUsers::RevokeAccessForm.new(user: @user)
  end

  def revoke_confirm
    @form = Admin::Form::EarlyAccessUsers::RevokeAccessForm.new(revoke_params.merge(user: @user))

    if @form.valid?
      @form.submit
      redirect_to admin_early_access_user_path(@user), notice: "Access revoked"
    else
      render :revoke, status: :unprocessable_entity
    end
  end

  def restore
    @user.update!(revoked_at: nil, revoked_reason: nil)

    redirect_to admin_early_access_user_path(@user), notice: "Access restored"
  end

private

  def find_user
    @user = EarlyAccessUser.find(params[:id])
  end

  def redirect_to_user_show_page_if_already_revoked
    redirect_to admin_early_access_user_path(@user) if @user.revoked?
  end

  def redirect_to_user_show_page_unless_revoked_or_banned
    redirect_to admin_early_access_user_path(@user) unless @user.revoked_or_banned?
  end

  def revoke_params
    params.require(:access_form).permit(:revoke_reason)
  end
end
