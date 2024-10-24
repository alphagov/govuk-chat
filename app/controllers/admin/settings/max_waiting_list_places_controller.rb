class Admin::Settings::MaxWaitingListPlacesController < Admin::BaseController
  def edit
    @form = Admin::Form::Settings::MaxWaitingListPlacesForm.new(
      max_places: Settings.instance.max_waiting_list_places,
    )
  end

  def update
    @form = Admin::Form::Settings::MaxWaitingListPlacesForm.new(update_params)

    if @form.valid?
      @form.submit
      redirect_to admin_settings_path, notice: "Maximum waiting list places updated"
    else
      render :edit, status: :unprocessable_entity
    end
  end

private

  def update_params
    params
      .require(:max_waiting_list_places_form)
      .permit(:max_places, :author_comment)
      .merge(user: current_user)
  end
end
