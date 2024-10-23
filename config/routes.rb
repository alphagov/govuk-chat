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

  html_constraint = { format: [Mime::Type.lookup("*/*"),
                               Mime::Type.lookup("text/html")] }
  html_json_constraint = { format: [Mime::Type.lookup("*/*"),
                                    Mime::Type.lookup("text/html"),
                                    Mime::Type.lookup("application/json")] }

  scope :chat, format: false, defaults: { format: "html" }, constraints: html_constraint do
    get "", to: "homepage#index", as: :homepage
    post "", to: "homepage#sign_in_or_up"

    scope "try-chat" do
      get "/you", to: "sign_up#user_description", as: :sign_up_user_description
      post "/you", to: "sign_up#confirm_user_description"

      get "/your-visit", to: "sign_up#reason_for_visit", as: :sign_up_reason_for_visit
      post "/your-visit", to: "sign_up#confirm_reason_for_visit"
    end

    get "sign-out", to: "sessions#destroy"
    get "sign-in/:id/:token", to: "sessions#confirm", as: :magic_link

    get "unsubscribe/waiting-list/:id/:token", to: "unsubscribe#waiting_list_user", as: :waiting_list_user_unsubscribe
    get "unsubscribe/early-access/:id/:token", to: "unsubscribe#early_access_user", as: :early_access_user_unsubscribe

    scope :onboarding, constraints: html_json_constraint do
      get "", to: "onboarding#limitations", as: :onboarding_limitations
      post "", to: "onboarding#limitations_confirm", as: :onboarding_limitations_confirm
      get "privacy", to: "onboarding#privacy", as: :onboarding_privacy
      post "privacy", to: "onboarding#privacy_confirm", as: :onboarding_privacy_confirm
    end

    scope :conversation do
      get "", to: "conversations#show", as: :show_conversation, constraints: html_json_constraint
      post "", to: "conversations#update", as: :update_conversation, constraints: html_json_constraint

      get "/questions/:question_id/answer", to: "conversations#answer",
                                            as: :answer_question,
                                            constraints: html_json_constraint

      post "/answers/:answer_id/feedback", to: "conversations#answer_feedback",
                                           as: :answer_feedback,
                                           constraints: html_json_constraint

      get "/clear", to: "conversations#clear", as: :clear_conversation
      post "/clear", to: "conversations#clear_confirm"
    end

    get "/about", to: "static#about"
    get "/support", to: "static#support"
    get "/privacy", to: redirect("#{Plek.website_root}/government/publications/govuk-chat-privacy-notice/govuk-chat-privacy-notice", status: 302)
    get "/accessibility", to: "static#accessibility"
  end

  namespace :admin, format: false, defaults: { format: "html" }, constraints: html_constraint do
    get "", to: "homepage#index", as: :homepage
    get "/questions", to: "questions#index", as: :questions
    get "/questions/:id", to: "questions#show", as: :show_question
    get "/search", to: "search#index", as: :search
    get "/search/chunk/:id", to: "chunks#show", as: :chunk
    scope :metrics do
      get "", to: "metrics#index", as: :metrics
      scope defaults: { format: "json" }, constraints: html_json_constraint do
        get "early-access-users", to: "metrics#early_access_users", as: :metrics_early_access_users
        get "waiting-list-users", to: "metrics#waiting_list_users", as: :metrics_waiting_list_users
        get "conversations", to: "metrics#conversations", as: :metrics_conversations
        get "questions", to: "metrics#questions", as: :metrics_questions
        get "answer-feedback", to: "metrics#answer_feedback", as: :metrics_answer_feedback
        get "answer-abort-statuses", to: "metrics#answer_abort_statuses", as: :metrics_answer_abort_statuses
        get "answer-error-statuses", to: "metrics#answer_error_statuses", as: :metrics_answer_error_statuses
        get "question-routing-labels", to: "metrics#question_routing_labels", as: :metrics_question_routing_labels
        get "answer-guardrails-failures", to: "metrics#answer_guardrails_failures", as: :metrics_answer_guardrails_failures
      end
    end

    resources :early_access_users, path: "/early-access-users" do
      get "/delete", to: "early_access_users#delete", as: :delete, on: :member
      get "/access/revoke", to: "early_access_users/access#revoke", as: :revoke, on: :member
      patch "/access/revoke", to: "early_access_users/access#revoke_confirm", as: :revoke_confirm, on: :member
      patch "/access/restore", to: "early_access_users/access#restore", as: :restore, on: :member
    end

    resources :waiting_list_users, path: "/waiting-list-users" do
      get "/delete", to: "waiting_list_users#delete", as: :delete, on: :member
      get "/promote", to: "waiting_list_users#promote", as: :promote, on: :member
      post "/promote", to: "waiting_list_users#promote_confirm", as: :promote_confirm, on: :member
    end

    scope :settings do
      get "", to: "settings#show", as: :settings

      get "/instant_access_places", to: "settings/instant_access_places#edit", as: :settings_edit_instant_access_places
      patch "/instant_access_places", to: "settings/instant_access_places#update", as: :settings_update_instant_access_places

      get "/delayed_access_places", to: "settings/delayed_access_places#edit", as: :settings_edit_delayed_access_places
      patch "/delayed_access_places", to: "settings/delayed_access_places#update", as: :settings_update_delayed_access_places

      get "/max_waiting_list_places", to: "settings/max_waiting_list_places#edit", as: :settings_edit_max_waiting_list_places
      patch "/max_waiting_list_places", to: "settings/max_waiting_list_places#update", as: :settings_update_max_waiting_list_places

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
    match "/429" => "errors#too_many_requests"
    match "/500" => "errors#internal_server_error"
  end

  constraints(GDS::SSO::AuthorisedUserConstraint.new(AdminUser::Permissions::DEVELOPER_TOOLS)) do
    mount Sidekiq::Web => "/sidekiq"

    mount GovukPublishingComponents::Engine, at: "/component-guide"
  end
end
