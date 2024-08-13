class Form::EarlyAccess::UserDescription
  include ActiveModel::Model
  include ActiveModel::Attributes

  CHOICE_PRESENCE_ERROR_MESSAGE = "Choose which option best described you".freeze

  attribute :choice

  validates :choice, presence: { message: CHOICE_PRESENCE_ERROR_MESSAGE }
end
