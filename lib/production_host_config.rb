module ProductionHostConfig
  HOSTS = [
    /\Achat\.(integration\.|staging\.)?publishing\.service\.gov\.uk\z/,
    /\Agovuk-chat(.*)?\.herokuapp\.com\z/,
  ].freeze

  HOST_AUTHORIZATION = {
    exclude: ->(request) { request.path.start_with?("/healthcheck") },
  }.freeze
end
