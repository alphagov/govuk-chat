module ProductionHostConfig
  HOSTS = [
    /chat\.(integration\.|staging\.)?publishing\.service\.gov\.uk/,
    /govuk-chat(.*)?\.herokuapp\.com/,
  ].freeze

  HOST_AUTHORIZATION = {
    exclude: ->(request) { request.path.start_with?("/healthcheck") },
  }.freeze
end
