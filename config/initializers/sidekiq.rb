Sidekiq.configure_client do |config|
  config.logger.level = Logger::WARN if Rails.env.test?
end
