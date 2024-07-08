module Healthcheck
  class Opensearch
    attr_reader :message

    def name
      :opensearch
    end

    def status
      client_options = Rails.configuration.opensearch.slice(:url, :user, :password)
      client = OpenSearch::Client.new(**client_options)
      health = client.cluster.health["status"]

      case health
      when "green"
        GovukHealthcheck::OK
      when "yellow"
        @message = "Cluster health is yellow"
        GovukHealthcheck::WARNING
      when "red"
        @message = "Cluster health is red"
        GovukHealthcheck::CRITICAL
      end
    rescue StandardError => e
      @message = e.message
      GovukHealthcheck::CRITICAL
    end
  end
end
