class ChatController < ApplicationController
  rescue_from ActionController::Redirecting::UnsafeRedirectError do |e|
    logger.error("Unsuccessful unsafe redirect: #{e.message}")
    redirect_to chat_path
  end

  def index
    expires_in(5.minutes, public: true) unless Rails.env.development?
  end

  def onboarding
    @form = Form::ConfirmUnderstandRisk.new
  end

  def onboarding_confirm
    @form = Form::ConfirmUnderstandRisk.new(
      confirmation: params.dig("confirm_understand_risk", "confirmation"),
    )

    if @form.valid?
      session[:chat_risks_understood] = true
      redirect_to(session.delete(:referrer) || new_conversation_path)
    else
      render :onboarding, status: :unprocessable_entity
    end
  end
end
