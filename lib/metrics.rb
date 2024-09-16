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
  ].freeze

  def self.register
    COUNTERS.each do |counter|
      PrometheusExporter::Client.default.register(
        :counter, name_with_prefix(counter[:name]), counter[:description]
      )
    end
  end

  def self.increment_counter(name, labels = {})
    if COUNTERS.none? { |counter| counter[:name] == name }
      GovukError.notify("#{name} is not defined in Metrics::COUNTERS")
      return
    end

    metric = PrometheusExporter::Client.default.find_registered_metric(name_with_prefix(name))
    metric.observe(1, labels)
  end

  def self.name_with_prefix(name)
    "#{PREFIX}#{name}"
  end
end
