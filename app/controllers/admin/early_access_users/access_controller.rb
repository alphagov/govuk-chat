class Admin::EarlyAccessUsers::AccessController < Admin::BaseController
  def revoke
    @user = EarlyAccessUser.find(params[:id])
    @form = Admin::Form::EarlyAccessUsers::RevokeAccessForm.new(user: @user)
  end

  def revoke_confirm
    @user = EarlyAccessUser.find(params[:id])
    @form = Admin::Form::EarlyAccessUsers::RevokeAccessForm.new(revoke_params.merge(user: @user))

    if @form.valid?
      @form.submit
      redirect_to admin_show_early_access_user_path(@user), notice: "Access revoked"
    else
      render :revoke, status: :unprocessable_entity
    end
  end

  def restore
    user = EarlyAccessUser.find(params[:id])
    user.update!(revoked_at: nil, revoked_reason: nil)

    redirect_to admin_show_early_access_user_path(user), notice: "Access restored"
  end

private

  def revoke_params
    params.require(:access_form).permit(:revoke_reason)
  end
end
