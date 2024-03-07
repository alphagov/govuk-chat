class Form::CreateQuestion
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :user_question

  validates :user_question, presence: { message: "Enter a question" }
  validates :user_question, length: { maximum: 300, message: "Question must be 300 characters or less" }

  def submit
    validate!

    conversation = Conversation.new
    question = Question.new(message: user_question, conversation:)
    question.save!
    question
  end
end
