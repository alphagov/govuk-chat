require "govuk_app_config/govuk_prometheus_exporter"
GovukPrometheusExporter.configure
Rails.configuration.after_initialize do
  Metrics.register
end
