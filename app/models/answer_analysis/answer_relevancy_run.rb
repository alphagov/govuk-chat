module AnswerAnalysis
  class AnswerRelevancyRun < ApplicationRecord
    include LlmCallsRecordable

    self.table_name = "answer_analysis_answer_relevancy_runs"

    belongs_to :aggregate,
               class_name: "AnswerAnalysis::AnswerRelevancyAggregate",
               foreign_key: :answer_analysis_answer_relevancy_aggregate_id
  end
end
