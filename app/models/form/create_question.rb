class Form::CreateQuestion
  include ActiveModel::Model
  include ActiveModel::Attributes

  EMAIL_REGEX = /[^\s=\/?&#]+(?:@|%40)[^\s=\/?&]/
  CREDIT_CARD_REGEX = /\d{13,16}/
  PHONE_NUMBER_REGEX = /\b\+?[(]?\d{3}[)]?[-\s.]?\d{3}[-\s.]?\d{4,6}\b/
  NATIONAL_INSURANCE_NUMBER_REGEX = /[A-Za-z]{2}\s?([0-9 ]+){6,8}\s?[A-Za-z]/
  PII_REGEXS = [EMAIL_REGEX, CREDIT_CARD_REGEX, PHONE_NUMBER_REGEX, NATIONAL_INSURANCE_NUMBER_REGEX].freeze

  attribute :user_question
  attribute :conversation, default: -> { Conversation.new }

  validates :user_question, presence: { message: "Enter a question" }
  validates :user_question, length: { maximum: 300, message: "Question must be 300 characters or less" }
  validate :all_questions_answered?
  validate :no_pii_present?, if: -> { user_question.present? }

  def submit
    validate!

    question = Question.create!(message: user_question, conversation:)
    if Feature.enabled?(:open_ai)
      GenerateAnswerFromOpenAiJob.perform_later(question.id)
    else
      GenerateAnswerFromChatApiJob.perform_later(question.id)
    end
    question
  end

private

  def all_questions_answered?
    if conversation.questions.unanswered.exists?
      errors.add(:base, "Previous question pending. Please wait for a response")
    end
  end

  def no_pii_present?
    if PII_REGEXS.any? { |regex| user_question.match?(regex) }
      error_message = "Personal data has been detected in your question. Please remove it. You can ask another question. " \
        "But please don’t include personal data in it or in any future questions."

      errors.add(:user_question, error_message)
    end
  end
end
