class Form::CreateAnswerFeedback
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :useful, :boolean
  attribute :answer

  validates :useful, inclusion: { in: [true, false], message: "Useful must be true or false" }
  validate :no_feedback_present?, if: -> { answer.present? }

  def submit
    validate!
    answer.create_feedback!(useful:)
  end

private

  def no_feedback_present?
    errors.add(:answer_feedback, "Feedback already provided") if answer.feedback.present?
  end
end
