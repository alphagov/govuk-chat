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

  def questions_for_showing_conversation(only_answered: false, before_timestamp_ms: nil)
    scope = Question.where(conversation: self)
                  .includes(answer: %i[feedback sources])
                  .active
    scope = scope.joins(:answer) if only_answered
    if before_timestamp_ms.present?
      time = Time.zone.at(before_timestamp_ms / 1000.0)
      scope = scope.where("questions.created_at < ?", time)
    end
    scope.last(Rails.configuration.conversations.api_conversation_questions_per_page)
  end

  def answered_questions_count
    Question.where(conversation: self).active.joins(:answer).count
  end
end
