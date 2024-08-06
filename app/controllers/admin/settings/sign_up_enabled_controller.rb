class Admin::Settings::SignUpEnabledController < Admin::BaseController
  def edit
    @form = Admin::Form::Settings::SignUpEnabledForm.new(
      enabled: Settings.instance.sign_up_enabled,
    )
  end

  def update
    @form = Admin::Form::Settings::SignUpEnabledForm.new(update_params)

    if @form.valid?
      @form.submit
      redirect_to admin_settings_path, notice: "Sign up enabled updated"
    else
      render :edit, status: :unprocessable_entity
    end
  end

private

  def update_params
    params
      .require(:sign_up_enabled_form)
      .permit(:enabled, :author_comment)
      .merge(user: current_user)
  end
end
