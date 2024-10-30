class Form::EarlyAccess::FoundChat
  include ActiveModel::Model
  include ActiveModel::Attributes

  CHOICE_ERROR_MESSAGE = "Select how you found out about GOV.UK Chat".freeze

  attribute :choice

  validates :choice, inclusion: { in: WaitingListUser.found_chat.keys, message: CHOICE_ERROR_MESSAGE }
end
