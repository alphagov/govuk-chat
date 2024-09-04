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
  ].freeze

  def self.register
    COUNTERS.each do |counter|
      PrometheusExporter::Client.default.register(
        :counter, name_with_prefix(counter[:name]), counter[:description], labels: %i[source]
      )
    end
  end

  def self.name_with_prefix(name)
    "#{PREFIX}#{name}"
  end
end
