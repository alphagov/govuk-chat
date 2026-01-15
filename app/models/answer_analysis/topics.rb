class AnswerAnalysis::Topics < ApplicationRecord
  include LlmCallsRecordable
  include AutoEvaluationResultsExportable

  self.table_name = "answer_analysis_topics"

  belongs_to :answer
end
