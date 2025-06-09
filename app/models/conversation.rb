class Conversation < ApplicationRecord
  has_many :questions
  has_many :answers, through: :questions
  belongs_to :signon_user, optional: true

  scope :active, -> { where(Question.active.where("questions.conversation_id = conversations.id").arel.exists) }

  enum :source,
       {
         api: "api",
         web: "web",
       },
       prefix: true

  def questions_for_showing_conversation(only_answered: false)
    scope = Question.where(conversation: self)
                  .includes(answer: %i[feedback sources])
                  .active
    scope = scope.joins(:answer) if only_answered
    scope.last(Rails.configuration.conversations.max_question_count)
  end
end
