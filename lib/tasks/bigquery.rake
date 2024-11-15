require "google/cloud/bigquery"

namespace :bigquery do
  desc "Export question and answer data to Bigquery"
  task export: :environment do
    exported = Bigquery::Exporter.call

    print "BigQuery Export: "

    puts "Records exported from #{exported[:from]} to #{exported[:until]}"
    exported[:tables].each do |table, count|
      puts "#{table} exported: #{count}"
    end
  end

  desc "Delete a table from BigQuery"
  task :delete_table, %i[table_name] => :environment do |_, args|
    bigquery = Google::Cloud::Bigquery.new
    dataset = bigquery.dataset(Rails.configuration.bigquery_dataset_id)
    table_name = args[:table_name]
    table = dataset.table(table_name)
    abort "BigQuery table doesn't exist: #{table_name}" unless table

    table.delete
    puts "Deleted #{table_name} table from BigQuery"
  end

  desc "Delete all of our known Big Query tables and our data of exports"
  task reset: :environment do
    bigquery = Google::Cloud::Bigquery.new
    dataset = bigquery.dataset(Rails.configuration.bigquery_dataset_id)

    deleted_tables = Bigquery::TABLES_TO_EXPORT.filter_map do |table|
      next unless dataset.table(table.name)

      dataset.table(table.name).delete
      table.name
    end

    puts "Deleted tables: #{deleted_tables.join(', ')}"

    records = BigqueryExport.delete_all

    puts "Deleted all #{records} BigqueryExport records"
  end
end
