# frozen_string_literal: true

source "https://rubygems.org"

ruby file: ".ruby-version"

gem "rails", "7.1.3.2"

gem "bootsnap"
gem "dartsass-rails"
gem "faraday"
gem "flipper"
gem "flipper-active_record"
gem "flipper-ui"
gem "govuk_app_config"
gem "govuk_publishing_components"
gem "govuk_sidekiq"
gem "inline_svg"
gem "pg"
gem "ruby-openai"
gem "sentry-sidekiq"
gem "sprockets-rails"

group :development do
  gem "brakeman"
end

group :test do
  gem "climate_control"
  gem "simplecov"
  gem "webmock"
end

group :development, :test do
  gem "dotenv"
  gem "factory_bot_rails"
  gem "govuk_test"
  gem "pry-rails"
  gem "rspec-rails"
  gem "rubocop-govuk", require: false
end
