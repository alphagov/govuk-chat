class Conversation < ApplicationRecord
  has_many :questions
  has_many :answers, through: :questions
  belongs_to :user, optional: true, class_name: "EarlyAccessUser", foreign_key: :early_access_user_id

  scope :active, -> { where(Question.active.where("questions.conversation_id = conversations.id").arel.exists) }

  def questions_for_showing_conversation
    Question.where(conversation: self)
            .includes(answer: %i[feedback sources])
            .active
            .last(Rails.configuration.conversations.max_question_count)
  end
end
