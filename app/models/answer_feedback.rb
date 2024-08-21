class AnswerFeedback < ApplicationRecord
  self.table_name = "answer_feedback"

  belongs_to :answer

  scope :exportable, lambda { |start_date, end_date|
                       where(created_at: start_date...end_date)
                     }

  def serialize_for_export
    as_json
  end
end
