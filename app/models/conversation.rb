class Conversation < ApplicationRecord
  has_many :questions

  scope :without_questions, lambda {
    left_outer_joins(:questions).where(questions: { conversation_id: nil })
  }
end
