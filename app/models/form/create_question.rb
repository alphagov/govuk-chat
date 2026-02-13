class Form::CreateQuestion
  include ActiveModel::Model
  include ActiveModel::Attributes
  include ActiveModel::Validations::Callbacks

  attribute :user_question
  attribute :conversation

  USER_QUESTION_PRESENCE_ERROR_MESSAGE = "Ask a question. For example, 'how do I register for VAT?'".freeze
  USER_QUESTION_LENGTH_MAXIMUM = 300
  USER_QUESTION_LENGTH_ERROR_MESSAGE = "Question must be %{count} characters or less".freeze
  USER_QUESTION_PII_ERROR_MESSAGE = "Personal data has been detected in your question. Please remove it and try asking again.".freeze
  UNANSWERED_QUESTION_ERROR_MESSAGE = "Previous question pending. Please wait for a response".freeze

  before_validation :sanitise_user_question, :normalise_newlines

  validates :user_question, presence: { message: USER_QUESTION_PRESENCE_ERROR_MESSAGE }
  validates :user_question, length: { maximum: USER_QUESTION_LENGTH_MAXIMUM, message: USER_QUESTION_LENGTH_ERROR_MESSAGE }
  validate :all_questions_answered?
  validate :no_pii_present?, if: -> { user_question.present? }

  def submit
    validate!

    question = Question.create!(
      answer_strategy: Rails.configuration.answer_strategy,
      message: @sanitised_user_question,
      unsanitised_message: (@unsanitised_user_question if @sanitised_user_question != @unsanitised_user_question),
      conversation:,
      conversation_session_id:,
    )

    ComposeAnswerJob.perform_later(question.id)

    question
  end

private

  def sanitise_user_question
    return if user_question == @unsanitised_user_question

    @unsanitised_user_question = user_question if user_question&.match?(UnicodeTags::MATCH_REGEX)
    @sanitised_user_question = user_question&.gsub(UnicodeTags::MATCH_REGEX, "")
  end

  def normalise_newlines
    user_question&.gsub!("\r\n", "\n")
  end

  def all_questions_answered?
    if conversation.questions.unanswered.exists?
      errors.add(:base, UNANSWERED_QUESTION_ERROR_MESSAGE)
    end
  end

  def no_pii_present?
    if PiiValidator.invalid?(user_question)
      errors.add(:user_question, USER_QUESTION_PII_ERROR_MESSAGE)
    end
  end

  def conversation_session_id
    return SecureRandom.uuid if conversation.new_record?

    latest_questions_session_id = Question.where(conversation:, created_at: 30.minutes.ago...)
                                          .order(created_at: :desc)
                                          .pick(:conversation_session_id)
    latest_questions_session_id || SecureRandom.uuid
  end
end
