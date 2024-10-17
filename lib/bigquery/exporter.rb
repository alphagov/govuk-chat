require "google/cloud/bigquery"

module Bigquery
  class Exporter
    class UploadFailedError < StandardError; end

    def self.remove_nil_values(json)
      case json
      when Array
        json.map { |el| remove_nil_values(el) }.compact
      when Hash
        json.transform_values { |v| remove_nil_values(v) }.compact
      else
        json
      end
    end

    def self.call(...) = new(...).call

    def initialize
      bigquery = Google::Cloud::Bigquery.new
      dataset_id = Rails.configuration.bigquery_dataset_id
      @dataset = bigquery.dataset(dataset_id)
    end

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

    attr_reader :dataset

    def export(export_from, export_until)
      exported_records = {}
      TOP_LEVEL_MODELS_TO_EXPORT.each do |model|
        records_to_export = model.exportable(export_from, export_until).map(&:serialize_for_export)
        table_id = model.table_name
        exported_records[table_id.to_sym] = records_to_export.size

        next unless records_to_export.any?

        tempfile = save_tables_to_json(self.class.remove_nil_values(records_to_export))
        upload_to_bigquery(tempfile, table_id)
      end

      MODELS_WITH_AGGREGATE_STATS_TO_EXPORT.each do |model|
        table_id = model.table_name
        json_to_export = model.aggregate_export_data(export_until)
        tempfile = save_tables_to_json([json_to_export])
        upload_to_bigquery(tempfile, table_id)
      end
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

    def upload_to_bigquery(tempfile, table_id)
      table = dataset.table(table_id)
      create_bigquery_table(table_id) unless table

      load_job = dataset.load_job(table_id, tempfile) do |config|
        config.autodetect = true
        config.format = "json"
        config.schema_update_options = %w[ALLOW_FIELD_ADDITION ALLOW_FIELD_RELAXATION]
      end

      load_job.wait_until_done!

      raise UploadFailedError, "BigQuery upload failed: #{load_job.error}" if load_job.failed?
    end

    def create_bigquery_table(table_id)
      expiration_duration = 1.year.to_i

      dataset.create_table(table_id) do |table|
        table.schema { |schema| schema.timestamp "created_at", mode: :required }
        table.time_partitioning_type = "DAY"
        table.time_partitioning_field = "created_at"
        table.time_partitioning_expiration = expiration_duration
      end
    end
  end
end
