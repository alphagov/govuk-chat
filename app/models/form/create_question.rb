class Form::CreateQuestion
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :user_question
  attribute :conversation, default: -> { Conversation.new }

  validates :user_question, presence: { message: "Enter a question" }
  validates :user_question, length: { maximum: 300, message: "Question must be 300 characters or less" }
  validate :all_questions_answered?

  def submit
    validate!

    question = Question.create!(message: user_question, conversation:)
    if Feature.enabled?(:open_ai)
      GenerateAnswerFromOpenAiJob.perform_later(question.id)
    else
      GenerateAnswerFromChatApi.perform_later(question.id)
    end
    question
  end

private

  def all_questions_answered?
    if conversation.questions.unanswered.exists?
      errors.add(:base, "Previous question pending. Please wait for a response")
    end
  end
end
