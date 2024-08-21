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

  desc "Reset local BigqueryExport table and drop tables already in BigQuery"
  task reset: :environment do
    Bigquery::Resetter.call
    puts "BigQuery Export: reset"
  end
end
