class Admin::Settings::WaitingListPromotionsPerRunController < Admin::BaseController
  def edit
    @form = Admin::Form::Settings::WaitingListPromotionsPerRunForm.new(
      promotions_per_run: Settings.instance.waiting_list_promotions_per_run,
    )
  end

  def update
    @form = Admin::Form::Settings::WaitingListPromotionsPerRunForm.new(update_params)

    if @form.valid?
      @form.submit
      redirect_to admin_settings_path, notice: "Waiting list promotions per run updated"
    else
      render :edit, status: :unprocessable_entity
    end
  end

private

  def update_params
    params
      .require(:waiting_list_promotions_per_run_form)
      .permit(:promotions_per_run, :author_comment)
      .merge(user: current_user)
  end
end
