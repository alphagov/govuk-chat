class Form::CreateAnswerFeedback
  include ActiveModel::Model
  include ActiveModel::Attributes

  REACTION_INCLUSION_ERROR_MESSAGE = "Reaction must be either 'positive' or 'negative'".freeze

  attribute :reaction
  attribute :answer

  validates :reaction, inclusion: { in: AnswerFeedback.reactions.keys, message: REACTION_INCLUSION_ERROR_MESSAGE }

  def submit
    validate!
    answer.create_feedback!(reaction:)
  end
end
