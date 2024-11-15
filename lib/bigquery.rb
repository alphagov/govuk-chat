module Bigquery
  TOP_LEVEL_MODELS_TO_EXPORT = [Question, AnswerFeedback].freeze
  MODELS_WITH_AGGREGATE_STATS_TO_EXPORT = [EarlyAccessUser, WaitingListUser].freeze

  ExportTable = Data.define(:name, :time_partitioning_field)

  TABLES_TO_EXPORT = [
    ExportTable.new(name: "questions", time_partitioning_field: "created_at"),
    ExportTable.new(name: "answer_feedback", time_partitioning_field: "created_at"),
    ExportTable.new(name: "early_access_users_aggregates", time_partitioning_field: "exported_until"),
    ExportTable.new(name: "waiting_list_users_aggregates", time_partitioning_field: "exported_until"),
    ExportTable.new(name: "smart_survey_responses", time_partitioning_field: "exported_until"),
  ].freeze
end
