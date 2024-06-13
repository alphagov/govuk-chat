class AnswerFeedback < ApplicationRecord
  self.table_name = "answer_feedback"

  belongs_to :answer
end
