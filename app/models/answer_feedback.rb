class AnswerFeedback < ApplicationRecord
  self.table_name = "answer_feedback"

  belongs_to :answer

  enum :reaction,
       {
         positive: "positive",
         negative: "negative",
       },
       prefix: true
end
