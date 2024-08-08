class EarlyAccessEntryController < ApplicationController
  def new
    @early_access_entry_form = Form::EarlyAccessEntry.new
  end

  def create
    @early_access_entry_form = Form::EarlyAccessEntry.new(form_params)
    @early_access_entry_form.submit
    ## TODO there will be other possible redirects here
    redirect_to action: :email_sent
  end

  def email_sent; end

private

  def form_params
    params.require(:form_early_access_entry).permit(:email)
  end
end
