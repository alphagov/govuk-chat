class Form::CreateQuestion
  include ActiveModel::Model
  include ActiveModel::Attributes
  include ActiveModel::Validations::Callbacks

  attribute :user_question
  attribute :conversation

  USER_QUESTION_PRESENCE_ERROR_MESSAGE = "Ask a question. For example, 'how do I register for VAT?'".freeze
  USER_QUESTION_LENGTH_MAXIMUM = 300
  USER_QUESTION_LENGTH_ERROR_MESSAGE = "Question must be %{count} characters or less".freeze

  before_validation :sanitise_user_question

  validates :user_question, presence: { message: USER_QUESTION_PRESENCE_ERROR_MESSAGE }
  validates :user_question, length: { maximum: USER_QUESTION_LENGTH_MAXIMUM, message: USER_QUESTION_LENGTH_ERROR_MESSAGE }
  validate :all_questions_answered?
  validate :no_pii_present?, if: -> { user_question.present? }
  validate :within_question_limit?

  def submit
    validate!

    question = Question.create!(
      answer_strategy: Rails.configuration.answer_strategy,
      message: @sanitised_user_question,
      unsanitised_message: (@unsanitised_user_question if @sanitised_user_question != @unsanitised_user_question),
      conversation:,
    )

    user = conversation.user
    user&.increment!(:questions_count)

    if user&.shadow_banned?
      ComposeAnswerJob.set(wait: rand(5..20).seconds).perform_later(question.id)
    else
      ComposeAnswerJob.perform_later(question.id)
    end

    question
  end

private

  def sanitise_user_question
    return if user_question == @unsanitised_user_question

    @unsanitised_user_question = user_question if user_question&.match?(UnicodeTags::MATCH_REGEX)
    @sanitised_user_question = user_question&.gsub(UnicodeTags::MATCH_REGEX, "")
  end

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

    errors.add(:base, "You’ve reached the message limit for the GOV.UK Chat trial. You have no messages left.")
  end
end
