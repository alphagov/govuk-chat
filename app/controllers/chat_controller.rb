class ChatController < ApplicationController
  def index
    expires_in(5.minutes, public: true) unless Rails.env.development?
  end

  def onboarding
    @form = Form::ConfirmUnderstandRisk.new
  end

  # TODO: redirect to the intially requested page - referrer
  def onboarding_confirm
    @form = Form::ConfirmUnderstandRisk.new(
      confirmation: params.dig("confirm_understand_risk", "confirmation"),
    )

    if @form.valid?
      session[:chat_risks_understood] = true
      redirect_to new_conversation_path
    else
      render :onboarding, status: :unprocessable_entity
    end
  end
end
