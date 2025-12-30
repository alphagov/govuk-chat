module Bigquery
  ExportTable = Data.define(:name, :time_partitioning_field, :model)

  TABLES_TO_EXPORT = [
    ExportTable.new(name: "questions", time_partitioning_field: "created_at", model: Question),
    ExportTable.new(name: "answer_feedback", time_partitioning_field: "created_at", model: AnswerFeedback),
    ExportTable.new(name: "answer_analysis_topics", time_partitioning_field: "created_at", model: AnswerAnalysis::Topics),
  ].freeze
end
