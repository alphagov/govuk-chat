module AnswerAnalysis
  class ContextRelevancyRun < ApplicationRecord
    include LlmCallsRecordable
    include AutoEvaluationResultsCreatable
    include AutoEvaluationResultsExportable

    self.table_name = "answer_analysis_context_relevancy_runs"

    belongs_to :answer

    enum :status, { success: "success", failure: "failure", error: "error" }
  end
end
