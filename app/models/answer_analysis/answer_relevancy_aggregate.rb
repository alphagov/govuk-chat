module AnswerAnalysis
  class AnswerRelevancyAggregate < ApplicationRecord
    include AnalysisResultsCreatable

    self.table_name = "answer_analysis_answer_relevancy_aggregates"

    belongs_to :answer
    has_many :runs,
             class_name: "AnswerAnalysis::AnswerRelevancyRun",
             foreign_key: :answer_analysis_answer_relevancy_aggregate_id
  end
end
