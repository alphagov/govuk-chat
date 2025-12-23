require "google/cloud/bigquery"

module Bigquery
  class Backfiller
    Result = Data.define(:name, :count, :exported_until)

    def self.call(...) = new.call(...)

    def initialize
      bigquery = Google::Cloud::Bigquery.new
      dataset_id = Rails.configuration.bigquery_dataset_id
      @dataset = bigquery.dataset(dataset_id)
    end

    def call(table)
      last_export = BigqueryExport.last

      raise "There are no exports so no need to backfill" unless last_export

      last_export.with_lock do
        export_until = last_export.exported_until
        export = IndividualExport.call(table.model, export_until:)

        delete_bigquery_table(table.name)

        if export.tempfile
          Uploader.call(table.name, export.tempfile, time_partitioning_field: table.time_partitioning_field)
        end

        Result.new(name: table.name, count: export.count, exported_until: export_until)
      end
    end

  private

    attr_reader :dataset

    def delete_bigquery_table(table_name)
      dataset.table(table_name)&.delete
    end
  end
end
