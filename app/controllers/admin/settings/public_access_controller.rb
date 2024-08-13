class Admin::Settings::PublicAccessController < Admin::BaseController
  def edit
    settings = Settings.instance
    @form = Admin::Form::Settings::PublicAccessForm.new(
      enabled: settings.public_access_enabled,
      downtime_type: settings.downtime_type,
    )
  end

  def update
    @form = Admin::Form::Settings::PublicAccessForm.new(update_params)

    if @form.valid?
      @form.submit
      redirect_to admin_settings_path, notice: "Public access updated"
    else
      render :edit, status: :unprocessable_entity
    end
  end

private

  def update_params
    params
      .require(:public_access_form)
      .permit(:enabled, :downtime_type, :author_comment)
      .merge(user: current_user)
  end
end
