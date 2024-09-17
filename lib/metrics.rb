class Metrics
  PREFIX = "govuk_chat_".freeze
  COUNTERS = [
    {
      name: "early_access_user_accounts_total",
      description: "The total number of early access users",
    },
    {
      name: "waiting_list_user_accounts_total",
      description: "The total number of waiting list users",
    },
    {
      name: "questions_total",
      description: "The total number of question asked",
    },
    {
      name: "answers_total",
      description: "The total number of answers created - success or failure",
    },
    {
      name: "answer_feedback_total",
      description: "The number of useful (yes/no) responses received",
    },
    {
      name: "conversations_total",
      description: "The total number of conversations",
    },
    {
      name: "login_total",
      description: "The total number of early access user logins",
    },
  ].freeze

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
    COUNTERS.each do |counter|
      PrometheusExporter::Client.default.register(
        :counter, name_with_prefix(counter[:name]), counter[:description]
      )
    end

    GAUGES.each do |gauge|
      PrometheusExporter::Client.default.register(
        :gauge, name_with_prefix(gauge[:name]), gauge[:description]
      )
    end
  end

  def self.increment_counter(name, labels = {})
    if COUNTERS.none? { |counter| counter[:name] == name }
      error = "#{name} is not defined in Metrics::COUNTERS"
      Rails.env.production? ? GovukError.notify(error) : (raise error)
      return
    end

    metric = PrometheusExporter::Client.default.find_registered_metric(name_with_prefix(name))
    metric.observe(1, labels)
  end

  def self.gauge(name, value, labels = {})
    if GAUGES.none? { |gauge| gauge[:name] == name }
      GovukError.notify("#{name} is not defined in Metrics::GAUGES")
      return
    end

    metric = PrometheusExporter::Client.default.find_registered_metric(name_with_prefix(name))
    metric.observe(value, labels)
  end

  def self.name_with_prefix(name)
    "#{PREFIX}#{name}"
  end
end
