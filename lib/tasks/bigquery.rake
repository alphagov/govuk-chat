require "google/cloud/bigquery"

namespace :bigquery do
  desc "Run an export of data to Bigquery"
  task export: :environment do
    result = Bigquery::Exporter.call

    puts "Records exported from #{result.exported_from} to #{result.exported_until}:"
    result.tables.each do |(table_name, count)|
      puts "Table #{table_name} (#{count})"
    end
  end

  desc "Backfill an export of a particular table up until last exported until"
  task :backfill_table, %i[table_name] => :environment do |_, args|
    table = Bigquery::TABLES_TO_EXPORT.find { |t| t.name == args[:table_name] }
    abort "Table #{args[:table_name]} is not a table we export to" unless table

    result = Bigquery::Backfiller.call(table)

    puts "Exported #{result.count} records for table #{table.name}"
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
