# frozen_string_literal: true

source "https://rubygems.org"

ruby "~> #{File.read('.ruby-version').strip}"

gem "rails", "7.2.1.1"

gem "bootsnap"
gem "chartkick"
gem "csv"
gem "dartsass-rails"
gem "faraday"
gem "faraday-typhoeus"
gem "gds-api-adapters"
gem "gds-sso"
gem "google-cloud-bigquery", require: false
gem "govuk_app_config"
gem "govuk_message_queue_consumer"
gem "govuk_publishing_components"
gem "govuk_sidekiq"
gem "groupdate"
gem "hashie"
gem "inline_svg"
gem "kaminari"
gem "kramdown"
gem "mail-notify"
gem "nokogiri"
gem "opensearch-ruby"
gem "passwordless"
gem "pg"
gem "prometheus_exporter"
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
