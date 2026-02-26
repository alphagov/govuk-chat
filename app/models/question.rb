class Question < ApplicationRecord
  enum :answer_strategy,
       {
         open_ai_rag_completion: "open_ai_rag_completion", # legacy strategy - no longer used
         openai_structured_answer: "openai_structured_answer",
         claude_structured_answer: "claude_structured_answer",
         non_llm_answer: "non_llm_answer", # only used during load testing, but can be present on records created during testing
       },
       prefix: true

  belongs_to :conversation

  # We frequently make use of question.answer and it'd be quite verbose to
  # always use an includes. Thus this is set to false, until we find evidence it
  # could solve more N+1 problems
  has_one :answer, strict_loading: false

  scope :unanswered, -> { where.missing(:answer) }
  scope :answered, -> { where.associated(:answer) }

  scope :group_by_status, lambda {
    left_outer_joins(:answer)
    .group("CASE WHEN answers.status IS NULL THEN 'pending' ELSE answers.status::TEXT END")
  }

  scope :group_by_aggregate_status, lambda {
    left_outer_joins(:answer)
    .group("CASE WHEN answers.status IS NULL THEN 'pending' ELSE SPLIT_PART(answers.status::TEXT, '_', 1) END")
  }

  scope :exportable, lambda { |start_date, end_date|
                       joins(:conversation, :answer)
                       .preload(:conversation, answer: { sources: :chunk })
                       .where("answer.created_at": start_date...end_date)
                     }

  scope :active, lambda {
    max_age = Rails.configuration.conversations.max_question_age_days.days.ago
    where("questions.created_at >= :max_age", max_age:)
  }

  delegate :use_in_rephrasing?, to: :answer

  def answer_status
    answer&.status || "pending"
  end

  def check_or_create_timeout_answer
    return answer if answer.present?

    age = Time.current - created_at
    if age >= Rails.configuration.conversations.answer_timeout_in_seconds
      create_answer(
        message: Answer::CannedResponses::TIMED_OUT_RESPONSE,
        status: :error_timeout,
        feedback: nil,
      )
    end
  end

  def serialize_for_export
    as_json.merge(
      "answer" => answer&.serialize_for_export,
      "source" => conversation.source,
      "signon_user_id" => conversation.signon_user_id,
      "end_user_id" => conversation.hashed_end_user_id,
    )
  end
end
