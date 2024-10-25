class Form::EarlyAccess::ReasonForVisit
  include ActiveModel::Model
  include ActiveModel::Attributes

  CHOICE_PRESENCE_ERROR_MESSAGE = "Select why you visited GOV.UK today".freeze

  attribute :choice

  validates :choice, presence: { message: CHOICE_PRESENCE_ERROR_MESSAGE }
end
