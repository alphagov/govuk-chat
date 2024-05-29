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
end
