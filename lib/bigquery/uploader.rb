require "google/cloud/bigquery"

module Bigquery
  class Uploader
    class UploadFailedError < StandardError; end

    def self.call(...) = new(...).call

    def initialize(table_id, tempfile, time_partitioning_field: "created_at")
      @table_id = table_id
      @tempfile = tempfile
      @time_partitioning_field = time_partitioning_field
    end

    def call
      create_bigquery_table
      upload_to_bigquery
    end

  private

    attr_reader :table_id, :tempfile, :time_partitioning_field

    def create_bigquery_table
      return if dataset.table(table_id).present?

      expiration_duration = 1.year.to_i

      dataset.create_table(table_id) do |table|
        table.schema { |schema| schema.timestamp time_partitioning_field, mode: :required }
        table.time_partitioning_type = "DAY"
        table.time_partitioning_field = time_partitioning_field
        table.time_partitioning_expiration = expiration_duration
      end
    end

    def upload_to_bigquery
      load_job = dataset.load_job(table_id, tempfile) do |config|
        config.autodetect = true
        config.format = "json"
        config.schema_update_options = %w[ALLOW_FIELD_ADDITION ALLOW_FIELD_RELAXATION]
      end

      load_job.wait_until_done!

      raise UploadFailedError, "BigQuery upload failed: #{load_job.error}" if load_job.failed?
    end

    def dataset
      @dataset ||= begin
        bigquery = Google::Cloud::Bigquery.new
        dataset_id = Rails.configuration.bigquery_dataset_id
        bigquery.dataset(dataset_id)
      end
    end
  end
end
