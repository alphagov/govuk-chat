# frozen_string_literal: true

Rails.application.routes.draw do
  root to: redirect("/chat")

  get "/healthcheck/live", to: proc { [200, {}, %w[OK]] }
  get "/healthcheck/ready", to: GovukHealthcheck.rack_response(
    GovukHealthcheck::SidekiqRedis,
  )

  scope :chat do
    get "", to: "conversations#new", as: :new_conversation
    post "/conversations", to: "conversations#create", as: :create_conversation

    patch "/conversations/:id", to: "conversations#update", as: :update_conversation

    get ":id", to: "conversations#show", as: :show_conversation
  end

  flipper_app = Flipper::UI.app
  mount flipper_app, at: "/flipper"
  mount GovukPublishingComponents::Engine, at: "/component-guide" if Rails.env.development?
end
