# frozen_string_literal: true

source "https://rubygems.org"

gem "rails", "7.1.3.2"

gem "bootsnap"
gem "dartsass-rails"
gem "flipper"
gem "flipper-active_record"
gem "govuk_app_config"
gem "govuk_publishing_components"
gem "govuk_sidekiq"
gem "pg"
gem "sentry-sidekiq"
gem "sprockets-rails"

group :development do
  gem "brakeman"
end

group :test do
  gem "simplecov"
end

group :development, :test do
  gem "factory_bot_rails"
  gem "govuk_test"
  gem "pry-rails"
  gem "rspec-rails"
  gem "rubocop-govuk", require: false
end
