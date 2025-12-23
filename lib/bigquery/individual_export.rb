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

    def call(model, export_from: nil, export_until: nil)
      records_to_export = model.exportable(export_from, export_until)
                                .map(&:serialize_for_export)
      export_data = self.class.remove_nil_values(records_to_export)

      save_export_data_to_tempfile(export_data)
    end

  private

    def save_export_data_to_tempfile(export_data)
      return Result.new(tempfile: nil, count: 0) unless export_data

      tempfile = Tempfile.new
      export_data.each { |record| tempfile.puts(record.to_json) }
      tempfile.rewind

      Result.new(tempfile:, count: export_data.count)
    end
  end
end
