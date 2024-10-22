require "google/cloud/bigquery"

module Bigquery
  class Exporter
    def self.remove_nil_values(json)
      case json
      when Array
        json.map { |el| remove_nil_values(el) }.compact.presence
      when Hash
        json.transform_values { |v| remove_nil_values(v) }.compact.presence
      else
        json
      end
    end

    def self.call(...) = new(...).call

    def call
      last_export = BigqueryExport.last || BigqueryExport.create!(exported_until: "2024-01-01")
      exported = {}
      last_export.with_lock do
        exported[:from] = last_export.exported_until
        exported[:until] = Time.current
        exported[:tables] = export(exported[:from], exported[:until])
        BigqueryExport.create!(exported_until: exported[:until])
      end
      exported
    end

  private

    def export(export_from, export_until)
      exported_records = {}
      TOP_LEVEL_MODELS_TO_EXPORT.each do |model|
        records_to_export = model.exportable(export_from, export_until).map(&:serialize_for_export)
        table_id = model.table_name
        exported_records[table_id.to_sym] = records_to_export.size

        next unless records_to_export.any?

        tempfile = save_tables_to_json(self.class.remove_nil_values(records_to_export))
        Uploader.call(table_id, tempfile)
      end

      MODELS_WITH_AGGREGATE_STATS_TO_EXPORT.each do |model|
        table_id = model.table_name
        json_to_export = model.aggregate_export_data(export_until)
        tempfile = save_tables_to_json([json_to_export])
        Uploader.call(table_id, tempfile, time_partitioning_field: "exported_until")
      end

      tempfile = save_tables_to_json([smart_survey_json])
      Uploader.call("smart_survey_responses", tempfile, time_partitioning_field: "exported_until")

      exported_records
    end

    def save_tables_to_json(records_to_export)
      tempfile = Tempfile.new

      records_to_export.each do |record|
        tempfile.puts(record.to_json)
      end

      tempfile.rewind
      tempfile
    end

    def smart_survey_json
      response_count = smart_survey_response.body["responses"]

      {
        "exported_until" => Time.current.as_json,
        "completed_surveys" => response_count,
      }
    end

    def smart_survey_response
      smary_survey_config = Rails.application.config.smart_survey

      conn = Faraday.new(
        url: "https://api.smartsurvey.io/v1/surveys/#{smary_survey_config.survey_id}",
        headers: {
          "Accept" => "application/json",
        },
      ) do |faraday|
        faraday.response :json
        faraday.response :raise_error
      end

      conn.set_basic_auth(smary_survey_config.api_key, smary_survey_config.api_key_secret)
      conn.get
    end
  end
end
