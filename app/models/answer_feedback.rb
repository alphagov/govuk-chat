class AnswerFeedback < ApplicationRecord
  self.table_name = "answer_feedback"

  belongs_to :answer

  scope :exportable, lambda { |start_date, end_date|
                       joins(answer: { question: :conversation })
                       .where(created_at: start_date...end_date)
                       .merge(Conversation.exclude_opted_out_end_user_ids)
                     }

  scope :group_useful_by_label,
        -> { group("CASE WHEN useful = true THEN 'useful' ELSE 'not useful' END") }

  def serialize_for_export
    as_json
  end
end
