# frozen_string_literal: true

source "https://rubygems.org"

ruby "~> #{File.read(File.join(__dir__, '.ruby-version')).strip}"

gem "rails", "8.0.2"

gem "anthropic"
gem "aws-sdk-bedrockruntime"
gem "blueprinter"
gem "bootsnap"
gem "chartkick"
gem "committee"
gem "csv"
gem "dalli"
gem "dartsass-rails"
gem "faraday"
gem "faraday-typhoeus"
gem "gds-api-adapters"
gem "gds-sso"
gem "google-cloud-bigquery", require: false
gem "govuk_app_config"
# gem "govuk_chat_private", github: "alphagov/govuk_chat_private"
# gem "govuk_chat_private", path: "../govuk_chat_private"
gem "govuk_chat_private", github: "alphagov/govuk_chat_private", branch: "eval-changes-question-handling"
gem "govuk_message_queue_consumer"
gem "govuk_publishing_components"
gem "govuk_sidekiq"
gem "groupdate"
gem "hashie"
gem "inline_svg"
gem "kaminari"
gem "kramdown"
gem "nokogiri"
gem "openapi3_parser"
gem "opensearch-ruby"
gem "pg"
gem "prometheus_exporter"
gem "rack-attack"
gem "ruby-openai"
gem "sentry-sidekiq"
gem "sprockets-rails"
gem "terser"
gem "tiktoken_ruby"

group :development do
  gem "brakeman"
end

group :test do
  gem "climate_control"
  gem "govuk_schemas"
  gem "simplecov"
  gem "webmock"
end

group :development, :test do
  gem "dotenv"
  gem "erb_lint", require: false
  gem "factory_bot_rails"
  gem "govuk_test"
  gem "pry-byebug"
  gem "pry-rails"
  gem "rspec-rails"
  gem "rubocop-govuk", require: false
end
