class Form::EarlyAccess::UserDescription
  include ActiveModel::Model
  include ActiveModel::Attributes

  CHOICE_ERROR_MESSAGE = "Select an option that best describes you".freeze

  attribute :choice

  validates :choice, inclusion: { in: WaitingListUser.user_descriptions.keys, message: CHOICE_ERROR_MESSAGE }
end
