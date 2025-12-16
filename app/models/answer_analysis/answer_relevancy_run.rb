module AnswerAnalysis
  class AnswerRelevancyRun < ApplicationRecord
    include LlmCallsRecordable

    belongs_to :aggregate,
               class_name: "AnswerAnalysis::AnswerRelevancyAggregate",
               foreign_key: :answer_relevancy_aggregate_id
  end
end
