class Form::EarlyAccess::ReasonForVisit
  include ActiveModel::Model
  include ActiveModel::Attributes

  CHOICE_ERROR_MESSAGE = "Select why you visited GOV.UK today".freeze

  attribute :choice

  validates :choice, inclusion: { in: WaitingListUser.reason_for_visit.keys, message: CHOICE_ERROR_MESSAGE }
end
