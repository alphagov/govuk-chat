module AnswerAnalysis
  class CoherenceRun < ApplicationRecord
    include LlmCallsRecordable
    include AutoEvaluationResultsCreatable

    self.table_name = "answer_analysis_coherence_runs"
    belongs_to :answer
  end
end
