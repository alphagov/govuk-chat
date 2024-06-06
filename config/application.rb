# frozen_string_literal: true

require_relative "boot"

require "rails"
# Pick the frameworks you want:
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
# require "active_storage/engine"
require "action_controller/railtie"
# require "action_mailer/railtie"
# require "action_mailbox/engine"
# require "action_text/engine"
require "action_view/railtie"
require "action_cable/engine"
# require "rails/test_unit/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module GovukChat
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.1

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")
    config.time_zone = "London"

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
    config.conversations = Hashie::Mash.new(max_question_age_days: 30, max_question_count: 500)

    config.openai_access_token = ENV["OPENAI_ACCESS_TOKEN"]

    config.llm_prompts = Hashie::Mash.new(YAML.load_file("#{__dir__}/llm_prompts.yml"))
    config.answer_statuses = Hashie::Mash.new(YAML.load_file("#{__dir__}/answer_statuses.yml"))
    config.search = Hashie::Mash.new(YAML.load_file("#{__dir__}/search.yml"))

    # List of forbidden words that will prevent a message from being sent to openAI
    config.question_forbidden_words = []

    config.action_dispatch.rescue_responses["Search::ChunkedContentRepository::NotFound"] = :not_found

    config.exceptions_app = routes

    config.available_without_signon_authentication = ENV["AVAILABLE_WITHOUT_SIGNON_AUTHENTICATION"]
  end
end
