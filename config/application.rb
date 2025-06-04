require_relative "boot"

require "rails"
# Pick the frameworks you want:
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
# require "active_storage/engine"
require "action_controller/railtie"
require "action_mailer/railtie"
# require "action_mailbox/engine"
# require "action_text/engine"
require "action_view/railtie"
require "action_cable/engine"
# require "rails/test_unit/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

Dotenv::Rails.files << ".env.aws.local" if Rails.env.development?

module GovukChat
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.0

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.eager_load_paths << Rails.root.join("extras")

    # Set asset path to be application specific so that we can put all GOV.UK
    # assets into an S3 bucket and distinguish app by path.
    config.assets.prefix = "/assets/chat"

    # Don't generate system test files.
    config.generators.system_tests = nil

    config.active_job.queue_adapter = :sidekiq

    # Prevent lazy loading of ActiveRecord associations, to avoid N+1 queries.
    # Can be disabled on an individual assocation with strict_loading: false
    config.active_record.strict_loading_by_default = true

    config.opensearch = config_for(:opensearch)
    config.conversations = Hashie::Mash.new(
      answer_timeout_in_seconds: 120,
      max_question_age_days: 30,
      max_question_count: 500,
      max_questions_per_user: 70,
      question_warning_threshold: 20,
    )
    config.instant_access_places_schedule = Hashie::Mash.new(
      not_before: Date.new(2024, 11, 7),
      not_after: Date.new(2024, 12, 22),
      places: ENV.fetch("INSTANT_ACCESS_PLACES_SCHEDULE_INCREMENT", "25").to_i,
      max_places: 200,
    )
    config.delayed_access_places_schedule = Hashie::Mash.new(
      not_before: Date.new(2024, 11, 8),
      not_after: Date.new(2024, 12, 22),
      places: ENV.fetch("DELAYED_ACCESS_PLACES_SCHEDULE_INCREMENT", "100").to_i,
      max_places: 500,
    )

    config.openai_access_token = ENV["OPENAI_ACCESS_TOKEN"]
    config.openai_request_timeout = 45

    config.answer_statuses = Hashie::Mash.new(YAML.load_file("#{__dir__}/answer_statuses.yml"))
    config.question_routing_labels = Hashie::Mash.new(YAML.load_file("#{__dir__}/question_routing_labels.yml"))
    config.search = Hashie::Mash.new(YAML.load_file("#{__dir__}/search.yml"))
    config.pilot_user_research_questions = Hashie::Mash.new(
      YAML.load_file("#{__dir__}/pilot_user_research_questions.yml"),
    )

    config.action_dispatch.rescue_responses.merge!(
      "Search::ChunkedContentRepository::NotFound" => :not_found,
      "ThrottledRequest" => :too_many_requests,
      "Committee::InvalidResponse" => :internal_server_error,
    )

    config.exceptions_app = routes

    config.available_without_signon_authentication = ENV.key?("AVAILABLE_WITHOUT_SIGNON_AUTHENTICATION")

    # Make session length predictable to reduce confusion of when session data is lost.
    config.session_store :cookie_store, key: "_govuk_chat_session", expire_after: 30.days

    config.conversation_js_progressive_disclosure_delay = nil

    config.bigquery_dataset_id = ENV["BIGQUERY_DATASET"]

    config.answer_strategy = ENV.fetch("ANSWER_STRATEGY", "openai_structured_answer")
    config.embedding_provider = ENV.fetch("EMBEDDING_PROVIDER", "openai")
  end
end
