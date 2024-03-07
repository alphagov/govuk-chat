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
  end

  mount GovukPublishingComponents::Engine, at: "/component-guide" if Rails.env.development?
end
