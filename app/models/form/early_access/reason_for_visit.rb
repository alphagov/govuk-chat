class Form::EarlyAccess::ReasonForVisit
  include ActiveModel::Model
  include ActiveModel::Attributes

  CHOICE_PRESENCE_ERROR_MESSAGE = "Choose why you visited GOV.UK today".freeze

  attribute :choice
  attribute :user_description
  attribute :email

  validates :choice, presence: { message: CHOICE_PRESENCE_ERROR_MESSAGE }

  def submit
    validate!

    user = EarlyAccessUser.create!(
      reason_for_visit: choice,
      email:,
      user_description:,
      source: "instant_signup",
    )
    session = Passwordless::Session.create!(authenticatable: user)
    EarlyAccessAuthMailer.sign_in(session).deliver_now
  end
end
