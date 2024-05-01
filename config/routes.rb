# frozen_string_literal: true

require "sidekiq/web"

Rails.application.routes.draw do
  root to: redirect("/chat")

  get "/healthcheck/live", to: proc { [200, {}, %w[OK]] }
  get "/healthcheck/ready", to: GovukHealthcheck.rack_response(
    GovukHealthcheck::SidekiqRedis,
  )

  scope :chat do
    get "", to: "chat#index", as: :chat
    get "/onboarding", to: "chat#onboarding", as: :chat_onboarding
    post "/onboarding", to: "chat#onboarding_confirm", as: :onboarding_confirm

    scope :conversations do
      get "", to: "conversations#new", as: :new_conversation
      post "", to: "conversations#create", as: :create_conversation

      patch "/:id", to: "conversations#update", as: :update_conversation

      get "/:id", to: "conversations#show", as: :show_conversation

      scope "/:conversation_id/questions" do
        get "/:id/answer", to: "questions#answer", as: :answer_question
      end
    end
  end

  namespace :admin do
    get "", to: "homepage#index", as: :homepage
  end

  scope via: :all do
    match "/400" => "errors#bad_request"
    match "/403" => "errors#forbidden"
    match "/404" => "errors#not_found"
    match "/422" => "errors#unprocessable_entity"
    match "/500" => "errors#internal_server_error"
  end

  constraints(GDS::SSO::AuthorisedUserConstraint.new(User::Permissions::DEVELOPER_TOOLS)) do
    mount Flipper::UI.app(Flipper) => "/flipper"
    mount Sidekiq::Web => "/sidekiq"
  end

  if Rails.env.development? || ENV["MOUNT_COMPONENT_GUIDE"] == "true"
    mount GovukPublishingComponents::Engine, at: "/component-guide"
  end
end
