# frozen_string_literal: true

require "sidekiq/web"

Rails.application.routes.draw do
  root to: redirect("/chat")

  get "/healthcheck/live", to: proc { [200, {}, %w[OK]] }
  get "/healthcheck/ready", to: GovukHealthcheck.rack_response(
    GovukHealthcheck::ActiveRecord,
    GovukHealthcheck::SidekiqRedis,
    Healthcheck::OpenAI,
    Healthcheck::Opensearch,
  )

  scope :chat do
    get "", to: "chat#index", as: :chat

    scope "try-chat" do
      get "", to: "early_access_entry#sign_in_or_up", as: :early_access_entry_sign_in_or_up
      post "", to: "early_access_entry#confirm_sign_in_or_up"

      get "/you", to: "early_access_entry#user_description", as: :early_access_entry_user_description
      post "/you", to: "early_access_entry#confirm_user_description"

      get "/your-visit", to: "early_access_entry#reason_for_visit", as: :early_access_entry_reason_for_visit
      post "/your-visit", to: "early_access_entry#confirm_reason_for_visit"
    end

    get "sign-out", to: "sessions#destroy"
    get "sign-in/:id/:token", to: "sessions#confirm", as: :magic_link

    scope :onboarding do
      get "", to: "onboarding#limitations", as: :onboarding_limitations
      post "", to: "onboarding#limitations_confirm", as: :onboarding_limitations_confirm
      get "privacy", to: "onboarding#privacy", as: :onboarding_privacy
      post "privacy", to: "onboarding#privacy_confirm", as: :onboarding_privacy_confirm
    end

    scope :conversation do
      get "", to: "conversations#show", as: :show_conversation
      post "", to: "conversations#update", as: :update_conversation

      get "/questions/:question_id/answer", to: "conversations#answer", as: :answer_question

      post "/answers/:answer_id/feedback", to: "conversations#answer_feedback", as: :answer_feedback
    end

    get "protected", to: "protected#index"
  end

  namespace :admin do
    get "", to: "homepage#index", as: :homepage
    get "/questions", to: "questions#index", as: :questions
    get "/questions/:id", to: "questions#show", as: :show_question
    get "/conversations/:id", to: "conversations#show", as: :show_conversation
    get "/search", to: "search#index", as: :search
    get "/search/chunk/:id", to: "chunks#show", as: :chunk
    get "/early-access-users", to: "early_access_users#index", as: :early_access_users

    scope :settings do
      get "", to: "settings#show", as: :settings

      get "/instant_access_places", to: "settings/instant_access_places#edit", as: :settings_edit_instant_access_places
      patch "/instant_access_places", to: "settings/instant_access_places#update", as: :settings_update_instant_access_places

      get "/delayed_access_places", to: "settings/delayed_access_places#edit", as: :settings_edit_delayed_access_places
      patch "/delayed_access_places", to: "settings/delayed_access_places#update", as: :settings_update_delayed_access_places

      get "/sign-up-enabled", to: "settings/sign_up_enabled#edit", as: :settings_edit_sign_up_enabled
      patch "/sign-up-enabled", to: "settings/sign_up_enabled#update", as: :settings_update_sign_up_enabled

      get "/public-access", to: "settings/public_access#edit", as: :settings_edit_public_access
      patch "/public-access", to: "settings/public_access#update", as: :settings_update_public_access

      get "/audits", to: "settings#audits", as: :settings_audits
    end
  end

  scope via: :all do
    match "/400" => "errors#bad_request"
    match "/403" => "errors#forbidden"
    match "/404" => "errors#not_found"
    match "/422" => "errors#unprocessable_entity"
    match "/500" => "errors#internal_server_error"
  end

  constraints(GDS::SSO::AuthorisedUserConstraint.new(AdminUser::Permissions::DEVELOPER_TOOLS)) do
    mount Flipper::UI.app(Flipper, {
      # GOV.UK infrastructure causes false positives on IP spoofing
      # We can remove this when X-Real-IP reflects the user client IP and the following is changed:
      # https://github.com/alphagov/govuk-helm-charts/blob/75c809ab1dda3039299ef477f59d576ff96d2463/charts/generic-govuk-app/templates/nginx-configmap.yaml#L110
      rack_protection: { except: %i[ip_spoofing] },
    }) => "/flipper"

    mount Sidekiq::Web => "/sidekiq"

    mount GovukPublishingComponents::Engine, at: "/component-guide"
  end
end
