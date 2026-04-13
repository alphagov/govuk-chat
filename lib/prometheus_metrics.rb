class PrometheusMetrics
  PREFIX = "govuk_chat_".freeze
  GAUGES = [
    {
      name: "rate_limit_api_user_read_percentage_used",
      description: "The percentage of request quota used for the API user for read requests",
    },
    {
      name: "rate_limit_api_user_write_percentage_used",
      description: "The percentage of request quota used for the API user for write requests",
    },
    {
      name: "message_queue_last_content_indexed_timestamp_seconds",
      description: "Unix timestamp of the last message queue content item indexed",
    },
  ].freeze

  COUNTERS = [
    {
      name: "answer_count",
      description: "The total number of answers",
    },
  ].freeze

  def self.register
    GAUGES.each do |gauge|
      PrometheusExporter::Client.default.register(
        :gauge, name_with_prefix(gauge[:name]), gauge[:description]
      )
    end

    COUNTERS.each do |counter|
      PrometheusExporter::Client.default.register(
        :counter, name_with_prefix(counter[:name]), counter[:description]
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

  def self.increment_counter(name, labels = {})
    if COUNTERS.none? { |counter| counter[:name] == name }
      error = "#{name} is not defined in PrometheusMetrics::COUNTERS"
      Rails.env.production? ? GovukError.notify(error) : (raise error)
      return
    end

    metric = PrometheusExporter::Client.default.find_registered_metric(name_with_prefix(name))
    metric.observe(1, labels)
  end

  def self.name_with_prefix(name)
    "#{PREFIX}#{name}"
  end
end
