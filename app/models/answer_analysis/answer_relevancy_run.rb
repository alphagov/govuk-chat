module AnswerAnalysis
  class AnswerRelevancyRun < ApplicationRecord
    include LlmCallsRecordable
    include AutoEvaluationResultsCreatable

    self.table_name = "answer_analysis_answer_relevancy_runs"

    belongs_to :answer
  end
end
