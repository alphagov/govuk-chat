class Admin::Form::EarlyAccessUsers::UpdateForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :question_limit
  attribute :user

  validates :question_limit,
            numericality: {
              only_integer: true,
              greater_than_or_equal_to: 0,
              message: "Question limit must be a number or blank",
            },
            allow_nil: true

  def submit
    validate!

    limit = question_limit

    if question_limit.present? && question_limit == Rails.configuration.conversations.max_questions_per_user
      limit = nil
    end

    user.update!(question_limit: limit)
  end
end
