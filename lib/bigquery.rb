module Bigquery
  ExportTable = Data.define(:name, :time_partitioning_field)

  TABLES_TO_EXPORT = [
    ExportTable.new(name: "questions", time_partitioning_field: "created_at"),
    ExportTable.new(name: "answer_feedback", time_partitioning_field: "created_at"),
    ExportTable.new(name: "answer_analysis", time_partitioning_field: "created_at"),
  ].freeze
end
