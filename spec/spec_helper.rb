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

# Inverse matchers for use in compound expecations
RSpec::Matchers.define_negated_matcher(:output_nothing, :output)
RSpec::Matchers.define_negated_matcher(:not_change, :change)

RSpec.configure do |config|
  WebMock.disable_net_connect!(allow: Rails.configuration.opensearch.url, allow_localhost: true)

  config.expose_dsl_globally = false
  config.infer_spec_type_from_file_location!
  config.use_transactional_fixtures = true
  config.order = :random
  Kernel.srand(config.seed)

  config.include ActiveSupport::Testing::TimeHelpers
  config.include AuthenticationHelpers, type: ->(spec) { spec.in?(%i[request system]) }
  config.include Capybara::RSpecMatchers, type: :request
  config.include FactoryBot::Syntax::Methods
  config.include StubOpenAIChat
  config.include StubBedrock
  config.include StubClaudeMessages
  config.include SidekiqHelpers
  config.include SystemSpecHelpers, type: :system

  config.before(:each, :chunked_content_index) do
    Search::ChunkedContentRepository.new.create_index!
    config.include SearchChunkedContentHelpers
  end

  config.before :suite do
    Rails.application.load_seed
  end

  config.before do
    Sidekiq::Queues.clear_all
  end

  # configure system specs
  config.before(:each, type: :system) do
    driven_by :rack_test
  end

  config.before(:each, :js, type: :system) do
    driven_by Capybara.javascript_driver
  end

  config.around do |example|
    ClimateControl.modify(GOVUK_WEBSITE_ROOT: "https://www.test.gov.uk") { example.run }
  end

  config.before(:each, :dismiss_cookie_banner, type: :system) do
    # The cookie banner for the session as it can break tests due to
    # them running in a small viewport.
    dismiss_cookie_banner
  end

  config.around(:each, :rack_attack) do |example|
    old_store = Rack::Attack.cache.store
    Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new
    example.run
    Rack::Attack.cache.store = old_store
  end

  config.around do |example|
    if !example.metadata[:type].in?(%i[system request])
      original_queue_adapter = ActiveJob::Base.queue_adapter
      ActiveJob::Base.queue_adapter = :test
      example.call
      ActiveJob::Base.queue_adapter = original_queue_adapter
    else
      example.call
    end
  end

  # Use the :aws_credentials_stubbed tag to stub AWS credentials in tests,
  # to avoid additional credential or token requests.
  config.around(:each, :aws_credentials_stubbed) do |example|
    old_config = Aws.config.dup
    Aws.config.update(
      credentials: Aws::Credentials.new("fake_access_key", "fake_secret_key"),
      region: "eu-west-1",
    )
    example.run
    Aws.config.replace(old_config)
  end
end
