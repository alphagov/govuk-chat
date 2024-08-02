class Admin::Settings::InstantAccessPlacesController < Admin::BaseController
  def edit
    @form = Admin::Form::Settings::InstantAccessPlacesForm.new
  end

  def update
    @form = Admin::Form::Settings::InstantAccessPlacesForm.new(update_params)

    if @form.valid?
      @form.submit
      redirect_to admin_settings_path, notice: "Instant access places updated"
    else
      render :edit, status: :unprocessable_entity
    end
  end

private

  def update_params
    params
      .require(:instant_access_places_form)
      .permit(:places, :author_comment)
      .merge(user: current_user)
  end
end
