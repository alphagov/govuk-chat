class Conversation < ApplicationRecord
  has_many :questions, strict_loading: true

  scope :active, -> { where(Question.active.where("questions.conversation_id = conversations.id").arel.exists) }

  def questions_for_showing_conversation
    Question.where(conversation: self)
            .includes(answer: :sources)
            .active
            .last(Rails.configuration.conversations.max_question_count)
  end
end
