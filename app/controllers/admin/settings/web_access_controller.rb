class Admin::Settings::WebAccessController < Admin::BaseController
  def edit
    settings = Settings.instance
    @form = Admin::Form::Settings::WebAccessForm.new(
      enabled: settings.web_access_enabled,
    )
  end

  def update
    @form = Admin::Form::Settings::WebAccessForm.new(update_params)

    if @form.valid?
      @form.submit
      redirect_to admin_settings_path, notice: "Web access updated"
    else
      render :edit, status: :unprocessable_entity
    end
  end

private

  def update_params
    params
      .require(:web_access_form)
      .permit(:enabled, :author_comment)
      .merge(user: current_user)
  end
end
