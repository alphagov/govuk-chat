module AnswerAnalysis
  class ContextRelevancyRun < ApplicationRecord
    include LlmCallsRecordable
    include AutoEvaluationResultsCreatable

    self.table_name = "answer_analysis_context_relevancy_runs"

    belongs_to :answer
  end
end
