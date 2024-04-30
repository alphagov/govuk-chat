# frozen_string_literal: true

ENV["RAILS_ENV"] ||= "test"

require "simplecov"
SimpleCov.start "rails"

require File.expand_path("../config/environment", __dir__)
require "govuk_message_queue_consumer/test_helpers"
require "govuk_sidekiq/testing"
require "rspec/rails"
require "webmock/rspec"

ActiveRecord::Migration.maintain_test_schema! # require all DB migrations to be run
Rails.application.load_tasks
Dir[Rails.root.join("spec/support/**/*.rb")].each { |f| require f }
GovukTest.configure

# Define a mathcher for the inverse of output, so that it can be used in
# assertion chains
RSpec::Matchers.define_negated_matcher(:output_nothing, :output)

RSpec.configure do |config|
  WebMock.disable_net_connect!(allow: Rails.configuration.opensearch.url)

  config.expose_dsl_globally = false
  config.infer_spec_type_from_file_location!
  config.use_transactional_fixtures = true
  config.order = :random
  Kernel.srand(config.seed)

  config.include FactoryBot::Syntax::Methods
  config.include AuthenticationHelpers, type: :request
  config.include Capybara::RSpecMatchers, type: :request
  config.include StubOpenAIChat
  config.include StubOpenAIEmbedding
  config.include StubChatApi
  config.include SystemSpecHelpers, type: :system

  config.before(:each, chunked_content_index: true) do
    Search::ChunkedContentRepository.new.create_index!
    config.include SearchChunkedContentHelpers
  end

  config.before :suite do
    Rails.application.load_seed
  end

  # configure system specs
  # TODO: open PR on govuk_test to configure drivers for
  # system specs then remove from here when dependency is bumped
  config.before(:each, type: :system) do
    driven_by :rack_test
  end

  config.before(:each, type: :system, js: true) do
    driven_by :selenium_chrome_headless
  end
end
