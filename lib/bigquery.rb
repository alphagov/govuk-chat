module Bigquery
  ExportTable = Data.define(:name, :time_partitioning_field, :model)

  TABLES_TO_EXPORT = [
    ExportTable.new(name: "questions", time_partitioning_field: "created_at", model: Question),
    ExportTable.new(name: "answer_feedback", time_partitioning_field: "created_at", model: AnswerFeedback),
    ExportTable.new(name: "answer_analysis_topics", time_partitioning_field: "created_at", model: AnswerAnalysis::Topics),
    ExportTable.new(name: "answer_analysis_answer_relevancy_runs", time_partitioning_field: "created_at", model: AnswerAnalysis::AnswerRelevancyRun),
    ExportTable.new(name: "answer_analysis_coherence_runs", time_partitioning_field: "created_at", model: AnswerAnalysis::CoherenceRun),
    ExportTable.new(name: "answer_analysis_context_relevancy_runs", time_partitioning_field: "created_at", model: AnswerAnalysis::ContextRelevancyRun),
    ExportTable.new(name: "answer_analysis_faithfulness_runs", time_partitioning_field: "created_at", model: AnswerAnalysis::FaithfulnessRun),
  ].freeze
end
