# frozen_string_literal: true

Rails.application.routes.draw do
  get "/healthcheck/live", to: proc { [200, {}, %w[OK]] }
  get "/healthcheck/ready", to: GovukHealthcheck.rack_response(
    GovukHealthcheck::SidekiqRedis,
  )

  mount GovukPublishingComponents::Engine, at: "/component-guide" if Rails.env.development?
end
