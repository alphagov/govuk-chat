class Question < ApplicationRecord
  belongs_to :conversation
  has_one :answer
  scope :unanswered, -> { left_outer_joins(:answer).where(answer: { id: nil }) }
end
