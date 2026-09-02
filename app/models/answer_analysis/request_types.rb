class AnswerAnalysis::RequestTypes < ApplicationRecord
  include LlmCallsRecordable
  include AutoEvaluationResultsExportable

  self.table_name = "answer_analysis_request_types"

  belongs_to :answer

  enum :status, { success: "success", error: "error" }
end
