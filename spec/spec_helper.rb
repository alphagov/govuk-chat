# frozen_string_literal: true

ENV["RAILS_ENV"] ||= "test"

require "simplecov"
SimpleCov.start "rails"

require File.expand_path("../config/environment", __dir__)
require "govuk_sidekiq/testing"
require "rspec/rails"

Dir[Rails.root.join("spec/support/**/*.rb")].each { |f| require f }
GovukTest.configure

RSpec.configure do |config|
  config.expose_dsl_globally = false
  config.infer_spec_type_from_file_location!
  config.use_transactional_fixtures = true
  config.include FactoryBot::Syntax::Methods
  config.include StubFeatureFlags
end
ActiveJob::Base.queue_adapter = :test
