class AnswerAnalysis < ApplicationRecord
  include LlmCallsRecordable

  belongs_to :answer
end
