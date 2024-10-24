class Form::EarlyAccess::ReasonForVisit
  include ActiveModel::Model
  include ActiveModel::Attributes

  class EarlyAccessUserConflictError < StandardError; end
  class WaitingListUserConflictError < StandardError; end
  Result = Data.define(:outcome, :user)

  CHOICE_PRESENCE_ERROR_MESSAGE = "Select why you visited GOV.UK today".freeze

  attribute :choice
  attribute :user_description
  attribute :email

  validates :choice, presence: { message: CHOICE_PRESENCE_ERROR_MESSAGE }

  def submit
    validate!

    raise EarlyAccessUserConflictError if EarlyAccessUser.exists?(email:)
    raise WaitingListUserConflictError if WaitingListUser.exists?(email:)

    settings = Settings.instance
    settings.with_lock do
      if settings.instant_access_places.zero? &&
          settings.max_waiting_list_places <= WaitingListUser.count
        return Result.new(outcome: :waiting_list_full, user: nil)
      end

      if settings.instant_access_places.zero?
        user = WaitingListUser.create!(
          reason_for_visit: choice,
          email:,
          user_description:,
          source: "insufficient_instant_places",
        )
        @result = Result.new(outcome: :waiting_list_user, user:)
      else
        user = EarlyAccessUser.create!(
          reason_for_visit: choice,
          email:,
          user_description:,
          source: "instant_signup",
        )
        @session = Passwordless::Session.create!(authenticatable: user)
        settings.update!(instant_access_places: settings.instant_access_places - 1)
        @result = Result.new(outcome: :early_access_user, user:)
      end
    end

    if @result.outcome == :early_access_user
      EarlyAccessAuthMailer.access_granted(@session).deliver_now
    else
      EarlyAccessAuthMailer.waitlist(@result.user).deliver_now
    end

    @result
  end
end
