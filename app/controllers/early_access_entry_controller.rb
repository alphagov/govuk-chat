class EarlyAccessEntryController < BaseController
  def new
    @early_access_entry_form = Form::EarlyAccessEntry.new
  end

  def create
    @early_access_entry_form = Form::EarlyAccessEntry.new(form_params)

    if @early_access_entry_form.valid?
      result = @early_access_entry_form.submit

      if result.outcome == :new_user
        session["sign_up"] = { "email" => result.email }
        redirect_to early_access_entry_user_description_path
      elsif result.outcome == :user_revoked
        render "shared/access_revoked", status: :forbidden
      else
        render :email_sent
      end
    else
      render :new, status: :unprocessable_entity
    end
  end

private

  def form_params
    params.require(:early_access_entry_form).permit(:email)
  end
end
