class Admin::EarlyAccessUsers::AccessController < Admin::BaseController
  before_action :find_user
  before_action :redirect_to_user_show_page_if_already_revoked, only: %i[revoke revoke_confirm]
  before_action :redirect_to_user_show_page_if_revoked_or_banned, only: %i[shadow_ban shadow_ban_confirm]
  before_action :redirect_to_user_show_page_unless_revoked_or_banned, only: %i[restore restore_confirm]

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

  def shadow_ban
    @form = Admin::Form::EarlyAccessUsers::ShadowBanForm.new(user: @user)
  end

  def shadow_ban_confirm
    @form = Admin::Form::EarlyAccessUsers::ShadowBanForm.new(shadow_ban_params.merge(user: @user))

    if @form.valid?
      @form.submit
      redirect_to admin_early_access_user_path(@user), notice: "User shadown banned"
    else
      render :shadow_ban, status: :unprocessable_entity
    end
  end

  def restore
    @form = Admin::Form::EarlyAccessUsers::RestoreAccessForm.new(user: @user)
  end

  def restore_confirm
    @form = Admin::Form::EarlyAccessUsers::RestoreAccessForm.new(restore_params.merge(user: @user))

    if @form.valid?
      @form.submit
      redirect_to admin_early_access_user_path(@user), notice: "Access restored"
    else
      render :restore, status: :unprocessable_entity
    end
  end

private

  def find_user
    @user = EarlyAccessUser.find(params[:id])
  end

  def redirect_to_user_show_page_if_already_revoked
    redirect_to admin_early_access_user_path(@user) if @user.revoked?
  end

  def redirect_to_user_show_page_if_revoked_or_banned
    redirect_to admin_early_access_user_path(@user) if @user.revoked_or_banned?
  end

  def redirect_to_user_show_page_unless_revoked_or_banned
    redirect_to admin_early_access_user_path(@user) unless @user.revoked_or_banned?
  end

  def revoke_params
    params.require(:access_form).permit(:revoke_reason)
  end

  def shadow_ban_params
    params.require(:shadow_ban_form).permit(:shadow_ban_reason)
  end

  def restore_params
    params.require(:restore_access_form).permit(:restored_reason)
  end
end
