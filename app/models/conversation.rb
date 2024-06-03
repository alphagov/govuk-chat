class Conversation < ApplicationRecord
  has_many :questions

  scope :without_questions, lambda {
    left_outer_joins(:questions).where(questions: { conversation_id: nil })
  }

  scope :active, -> { where(Question.active.where("questions.conversation_id = conversations.id").arel.exists) }

  def questions_for_showing_conversation
    questions.active.last(Rails.configuration.conversations.max_question_count)
  end
end
