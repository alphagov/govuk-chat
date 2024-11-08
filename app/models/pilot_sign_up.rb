class PilotSignUp
  class EarlyAccessUserConflictError < StandardError; end
  class WaitingListUserConflictError < StandardError; end
  Result = Data.define(:outcome, :user, :session)

  def self.call(...) = new(...).call

  def initialize(email:, user_description:, reason_for_visit:, found_chat:, previous_sign_up_denied:)
    @email = email
    @user_description = user_description
    @reason_for_visit = reason_for_visit
    @found_chat = found_chat
    @settings = Settings.instance
    @previous_sign_up_denied = previous_sign_up_denied
  end

  def call
    raise EarlyAccessUserConflictError if EarlyAccessUser.exists?(email:)
    raise WaitingListUserConflictError if WaitingListUser.exists?(email:)

    result = settings.with_lock do
      if waiting_list_full?
        Result.new(outcome: :waiting_list_full, user: nil, session: nil)
      elsif settings.instant_access_places.zero?
        user = setup_waiting_list_user
        Result.new(outcome: :waiting_list_user, user:, session: nil)
      else
        user, session = setup_early_access_user
        Result.new(outcome: :early_access_user, user:, session:)
      end
    end

    EarlyAccessAuthMailer.access_granted(result.session).deliver_now if result.outcome == :early_access_user

    if result.outcome == :waiting_list_user
      EarlyAccessAuthMailer.waitlist(result.user).deliver_now
      if WaitingListUser.count == settings.max_waiting_list_places
        NotifySlackWaitingListFullJob.perform_later
      end
    end

    result
  end

private

  attr_reader :email, :user_description, :reason_for_visit, :found_chat, :settings, :previous_sign_up_denied

  def waiting_list_full?
    settings.instant_access_places.zero? &&
      settings.max_waiting_list_places <= WaitingListUser.count
  end

  def setup_early_access_user
    user = EarlyAccessUser.create!(
      email:,
      user_description:,
      reason_for_visit:,
      found_chat:,
      source: "instant_signup",
      previous_sign_up_denied:,
    )
    settings.update!(instant_access_places: settings.instant_access_places - 1)
    session = Passwordless::Session.create!(authenticatable: user)
    [user, session]
  end

  def setup_waiting_list_user
    WaitingListUser.create!(
      email:,
      user_description:,
      reason_for_visit:,
      found_chat:,
      source: "insufficient_instant_places",
      previous_sign_up_denied:,
    )
  end
end
