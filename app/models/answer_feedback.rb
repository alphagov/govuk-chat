class AnswerFeedback < ApplicationRecord
  self.table_name = "answer_feedback"

  after_commit :send_answer_feedback_total_to_prometheus, on: :create

  belongs_to :answer

  scope :exportable, lambda { |start_date, end_date|
                       where(created_at: start_date...end_date)
                     }

  scope :group_useful_by_label,
        -> { group("CASE WHEN useful = true THEN 'useful' ELSE 'not useful' END") }

  def serialize_for_export
    as_json
  end

private

  def send_answer_feedback_total_to_prometheus
    Metrics.increment_counter("answer_feedback_total", useful:)
  end
end
