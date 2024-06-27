class Question < ApplicationRecord
  enum :answer_strategy,
       {
         open_ai_rag_completion: "open_ai_rag_completion",
         govuk_chat_api: "govuk_chat_api",
       },
       prefix: true

  belongs_to :conversation

  # We frequently make use of question.answer and it'd be quite verbose to
  # always use an includes. Thus this is set to false, until we find evidence it
  # could solve more N+1 problems
  has_one :answer, strict_loading: false

  scope :unanswered, -> { where.missing(:answer) }

  scope :active, lambda {
    max_age = Rails.configuration.conversations.max_question_age_days.days.ago
    where("questions.created_at >= :max_age", max_age:)
  }

  def answer_status
    answer&.status || "pending"
  end

  def check_or_create_timeout_answer
    return answer if answer.present?

    age = Time.current - created_at
    if age >= Rails.configuration.conversations.answer_timeout_in_seconds
      create_answer(
        message: Answer::CannedResponses::TIMED_OUT_RESPONSE,
        status: :abort_timeout,
      )
    end
  end
end
