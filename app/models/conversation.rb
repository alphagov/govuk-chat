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

  def questions_for_showing_conversation(only_answered: false, before_id: nil, after_id: nil)
    scope = Question.where(conversation: self)
                  .includes(answer: %i[feedback sources])
                  .active
    scope = scope.joins(:answer) if only_answered

    if before_id.present?
      before_timestamp = scope.where(id: before_id).pick(:created_at) || raise(ActiveRecord::RecordNotFound)
      scope = scope.where("questions.created_at < ?", before_timestamp)
    end

    if after_id.present?
      after_timestamp = scope.where(id: after_id).pick(:created_at) || raise(ActiveRecord::RecordNotFound)
      scope = scope.where("questions.created_at > ?", after_timestamp)
    end

    scope.last(Rails.configuration.conversations.max_question_count)
  end
end
