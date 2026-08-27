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

  def self.hashed_end_user_id(end_user_id)
    return nil if end_user_id.blank?

    OpenSSL::HMAC.hexdigest(
      "SHA256",
      Rails.application.secret_key_base,
      end_user_id,
    )
  end

  def questions_for_showing_conversation(only_answered: false, before_id: nil, after_id: nil, limit: nil)
    scope = Question.where(conversation: self)
                  .includes(answer: [{ sources: :chunk }, :feedback])
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

    scope = scope.limit(limit || Rails.configuration.conversations.max_question_count)

    if before_id.blank? && after_id.present?
      scope.order(created_at: :asc)
    else
      scope.order(created_at: :desc).reverse
    end
  end

  def active_answered_questions_before?(timestamp)
    questions.active.answered.where("questions.created_at < ?", timestamp).exists?
  end

  def active_answered_questions_after?(timestamp)
    questions.active.answered.where("questions.created_at > ?", timestamp).exists?
  end

  def hashed_end_user_id
    return nil if end_user_id.blank?

    self.class.hashed_end_user_id(end_user_id)
  end
end
