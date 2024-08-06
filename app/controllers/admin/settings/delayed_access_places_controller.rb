class Admin::Settings::DelayedAccessPlacesController < Admin::BaseController
  def edit
    @form = Admin::Form::Settings::DelayedAccessPlacesForm.new
  end

  def update
    @form = Admin::Form::Settings::DelayedAccessPlacesForm.new(update_params)

    if @form.valid?
      @form.submit
      redirect_to admin_settings_path, notice: "Delayed access places updated"
    else
      render :edit, status: :unprocessable_entity
    end
  end

private

  def update_params
    params
      .require(:delayed_access_places_form)
      .permit(:places, :author_comment)
      .merge(user: current_user)
  end
end
