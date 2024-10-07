class PrometheusMetrics
  PREFIX = "govuk_chat_".freeze
  GAUGES = [
    {
      name: "openai_remaining_tokens",
      description: "The number of remaining tokens for the OpenAI API",
    },
    {
      name: "openai_remaining_requests",
      description: "The number of remaining requests for the OpenAI API",
    },
    {
      name: "openai_tokens_used_percentage",
      description: "The percentage of available tokens for the OpenAI API that have been used",
    },
    {
      name: "openai_requests_used_percentage",
      description: "The percentage of available requests for the OpenAI API that have been used",
    },
  ].freeze

  def self.register
    GAUGES.each do |gauge|
      PrometheusExporter::Client.default.register(
        :gauge, name_with_prefix(gauge[:name]), gauge[:description]
      )
    end
  end

  def self.gauge(name, value, labels = {})
    if GAUGES.none? { |gauge| gauge[:name] == name }
      error = "#{name} is not defined in PrometheusMetrics::GAUGES"
      Rails.env.production? ? GovukError.notify(error) : (raise error)
      return
    end

    metric = PrometheusExporter::Client.default.find_registered_metric(name_with_prefix(name))
    metric.observe(value, labels)
  end

  def self.name_with_prefix(name)
    "#{PREFIX}#{name}"
  end
end
