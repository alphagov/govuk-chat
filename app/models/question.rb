class Question < ApplicationRecord
  enum :answer_strategy,
       {
         open_ai_rag_completion: "open_ai_rag_completion",
         govuk_chat_api: "govuk_chat_api",
       },
       prefix: true

  belongs_to :conversation
  has_one :answer
  scope :unanswered, -> { left_outer_joins(:answer).where(answer: { id: nil }) }

  def answer_status
    answer&.status || "pending"
  end

  scope :active, lambda {
    max_age = Rails.configuration.conversations.max_question_age_days.days.ago
    where("questions.created_at >= :max_age", max_age:)
  }

  scope :for_display, -> { active.last(Rails.configuration.conversations.max_question_count) }
end
