require "google/cloud/bigquery"

module Bigquery
  class IndividualExport
    Result = Data.define(:tempfile, :count)

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

    def self.call(...) = new.call(...)

    def call(table_name, export_from: nil, export_until: nil)
      export_data = case table_name
                    when "smart_survey_responses"
                      [smart_survey_json]
                    when /_aggregates$/
                      model = model_for_table_name(table_name)
                      [model.aggregate_export_data(export_until)]
                    else
                      model = model_for_table_name(table_name)
                      records_to_export = model.exportable(export_from, export_until)
                                                .map(&:serialize_for_export)
                      self.class.remove_nil_values(records_to_export)
                    end

      save_export_data_to_tempfile(export_data)
    end

  private

    def model_for_table_name(table_name)
      without_aggregate = table_name.delete_suffix("_aggregates")
      without_aggregate.singularize.camelize.constantize
    end

    def save_export_data_to_tempfile(export_data)
      return Result.new(tempfile: nil, count: 0) unless export_data

      tempfile = Tempfile.new
      export_data.each { |record| tempfile.puts(record.to_json) }
      tempfile.rewind

      Result.new(tempfile:, count: export_data.count)
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
