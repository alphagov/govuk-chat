# frozen_string_literal: true

Rails.application.routes.draw do
  root to: redirect("/chat/conversations")

  get "/healthcheck/live", to: proc { [200, {}, %w[OK]] }
  get "/healthcheck/ready", to: GovukHealthcheck.rack_response(
    GovukHealthcheck::SidekiqRedis,
  )

  scope :chat do
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

  flipper_app = Flipper::UI.app
  mount flipper_app, at: "/flipper"

  if Rails.env.development? || ENV["MOUNT_COMPONENT_GUIDE"] == "true"
    mount GovukPublishingComponents::Engine, at: "/component-guide"
  end
end
