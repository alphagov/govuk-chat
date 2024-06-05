# frozen_string_literal: true

source "https://rubygems.org"

ruby file: ".ruby-version"

gem "rails", "7.1.3.4"

gem "bootsnap"
gem "dartsass-rails"
gem "erb_lint", require: false
gem "faraday"
gem "faraday-typhoeus"
gem "flipper"
gem "flipper-active_record"
gem "flipper-ui"
gem "gds-api-adapters"
gem "gds-sso"
gem "govuk_app_config"
gem "govuk_message_queue_consumer"
gem "govuk_publishing_components"
gem "govuk_sidekiq"
gem "hashie"
gem "inline_svg"
gem "kaminari"
gem "opensearch-ruby" # may need opensearch-aws-sigv4 for prod
gem "pg"
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
  gem "factory_bot_rails"
  gem "govuk_test"
  gem "pry-byebug"
  gem "pry-rails"
  gem "rspec-rails"
  gem "rubocop-govuk", require: false
end
