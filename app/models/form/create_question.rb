class Form::CreateQuestion
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :user_question
  attribute :conversation

  USER_QUESTION_PRESENCE_ERROR_MESSAGE = "Ask a question. For example, 'how do I register for VAT?'".freeze
  USER_QUESTION_LENGTH_MAXIMUM = 300
  USER_QUESTION_LENGTH_ERROR_MESSAGE = "Question must be %{count} characters or less".freeze

  validates :user_question, presence: { message: USER_QUESTION_PRESENCE_ERROR_MESSAGE }
  validates :user_question, length: { maximum: USER_QUESTION_LENGTH_MAXIMUM, message: USER_QUESTION_LENGTH_ERROR_MESSAGE }
  validate :all_questions_answered?
  validate :no_pii_present?, if: -> { user_question.present? }
  validate :within_question_limit?

  def submit
    validate!

    question = Question.new(message: user_question, conversation:)
    question.answer_strategy = :open_ai_rag_completion if Feature.enabled?(:unstructured_answer_generation)
    question.save!
    conversation.user.increment!(:questions_count) if conversation.user.present?
    ComposeAnswerJob.perform_later(question.id)
    question
  end

private

  def all_questions_answered?
    if conversation.questions.unanswered.exists?
      errors.add(:base, "Previous question pending. Please wait for a response")
    end
  end

  def no_pii_present?
    if PiiValidator.invalid?(user_question)
      error_message = "Personal data has been detected in your question. Please remove it and try asking again."

      errors.add(:user_question, error_message)
    end
  end

  def within_question_limit?
    return if conversation.user.nil?
    return unless conversation.user.question_limit_reached?

    errors.add(:base, "You have asked the maximum number of questions. You cannot ask any more.")
  end

  def answer_strategy
    if Feature.enabled?(:unstructured_answer_generation)
      :open_ai_rag_completion
    else
      :openai_structured_answer
    end
  end
end
