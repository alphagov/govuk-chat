require "google/cloud/bigquery"

module Bigquery
  class Resetter
    def self.call(...) = new(...).call

    def initialize
      bigquery = Google::Cloud::Bigquery.new
      dataset_id = Rails.configuration.bigquery_dataset_id
      @dataset = bigquery.dataset(dataset_id)
    end

    def call
      (TOP_LEVEL_MODELS_TO_EXPORT + MODELS_WITH_AGGREGATE_STATS_TO_EXPORT).each do |model|
        table_id = model.table_name

        dataset.table(table_id)&.delete
        BigqueryExport.delete_all
      end
    end

  private

    attr_reader :dataset
  end
end
