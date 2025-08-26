class Admin::Settings::ApiAccessController < Admin::BaseController
  before_action :authorise_admin_settings

  def edit
    settings = Settings.instance
    @form = Admin::Form::Settings::ApiAccessForm.new(
      enabled: settings.api_access_enabled,
    )
  end

  def update
    @form = Admin::Form::Settings::ApiAccessForm.new(update_params)

    if @form.valid?
      @form.submit
      redirect_to admin_settings_path, notice: "API access updated"
    else
      render :edit, status: :unprocessable_content
    end
  end

private

  def update_params
    params
      .require(:api_access_form)
      .permit(:enabled)
      .merge(user: current_user)
  end
end
