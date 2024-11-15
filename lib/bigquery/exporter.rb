module Bigquery
  class Exporter
    Result = Data.define(:exported_from, :exported_until, :tables)

    def self.call(...) = new(...).call

    def call
      last_export = BigqueryExport.last || BigqueryExport.create!(exported_until: "2024-01-01")
      last_export.with_lock do
        export_from = last_export.exported_until
        export_until = Time.current
        tables = export(export_from, export_until)

        BigqueryExport.create!(exported_until: export_until)

        Result.new(exported_from: export_from,
                   exported_until: export_until,
                   tables:)
      end
    end

  private

    def export(export_from, export_until)
      tables = TABLES_TO_EXPORT.map do |table|
        export = IndividualExport.call(table.name, export_from:, export_until:)

        {
          name: table.name,
          tempfile: export.tempfile,
          options: { time_partitioning_field: table.time_partitioning_field },
          count: export.count,
        }
      end

      tables.each_with_object({}) do |table, memo|
        Uploader.call(table[:name], table[:tempfile], **table[:options]) if table[:tempfile]

        memo[table[:name]] = table[:count]
      end
    end
  end
end
