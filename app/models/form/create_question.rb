class Form::CreateQuestion
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :user_question
  attribute :conversation, default: -> { Conversation.new }

  validates :user_question, presence: { message: "Enter a question" }
  validates :user_question, length: { maximum: 300, message: "Question must be 300 characters or less" }
  validate :all_questions_answered?
  validate :no_pii_present?, if: -> { user_question.present? }

  def submit
    validate!

    question = Question.create!(message: user_question, conversation:, answer_strategy:)
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
      error_message = "Personal data has been detected in your question. Please remove it. You can ask another question. " \
        "But please don’t include personal data in it or in any future questions."

      errors.add(:user_question, error_message)
    end
  end

  def answer_strategy
    if Feature.enabled?(:chat_api)
      :govuk_chat_api
    else
      :open_ai_rag_completion
    end
  end
end
