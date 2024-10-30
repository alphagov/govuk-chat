class Form::EarlyAccess::FoundChat
  include ActiveModel::Model
  include ActiveModel::Attributes

  CHOICE_PRESENCE_ERROR_MESSAGE = "Select how you found out about GOV.UK Chat".freeze

  attribute :choice

  validates :choice, presence: { message: CHOICE_PRESENCE_ERROR_MESSAGE }
end
