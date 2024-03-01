# frozen_string_literal: true

source "https://rubygems.org"

gem "rails", "7.1.3"

gem "bootsnap"
gem "govuk_app_config"
gem "pg"
gem "sprockets-rails"

group :development do
  gem "brakeman"
end

group :test do
  gem "simplecov"
end

group :development, :test do
  gem "govuk_test"
  gem "pry-rails"
  gem "rspec-rails"
  gem "rubocop-govuk", require: false
end
