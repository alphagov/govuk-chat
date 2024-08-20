class Form::EarlyAccess::ReasonForVisit
  include ActiveModel::Model
  include ActiveModel::Attributes

  class EarlyAccessUserConflictError < StandardError; end

  CHOICE_PRESENCE_ERROR_MESSAGE = "Choose why you visited GOV.UK today".freeze

  attribute :choice
  attribute :user_description
  attribute :email

  validates :choice, presence: { message: CHOICE_PRESENCE_ERROR_MESSAGE }

  def submit
    validate!

    settings = Settings.instance
    settings.with_lock do
      # This is a temporary measure until we add the waiting list
      raise "No places available" if settings.instant_access_places.zero?

      user = EarlyAccessUser.create!(
        reason_for_visit: choice,
        email:,
        user_description:,
        source: "instant_signup",
      )
      @session = Passwordless::Session.create!(authenticatable: user)
      settings.update!(instant_access_places: settings.instant_access_places - 1)
    rescue ActiveRecord::RecordNotUnique
      raise EarlyAccessUserConflictError
    end
    EarlyAccessAuthMailer.sign_in(@session).deliver_now
  end
end
