class Form::EarlyAccess::UserDescription
  include ActiveModel::Model
  include ActiveModel::Attributes

  CHOICE_PRESENCE_ERROR_MESSAGE = "Select an option that best describes you".freeze

  attribute :choice

  validates :choice, presence: { message: CHOICE_PRESENCE_ERROR_MESSAGE }
end
