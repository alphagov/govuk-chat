class Form::EarlyAccess::SignInOrUp
  include ActiveModel::Model
  include ActiveModel::Attributes

  Result = Data.define(:outcome, :user, :email)

  EMAIL_ADDRESS_PRESENCE_ERROR_MESSAGE = "Enter an email address".freeze
  EMAIL_ADDRESS_LENGTH_ERROR_MESSAGE = "Email must be %{count} characters or less".freeze
  EMAIL_ADDRESS_FORMAT_ERROR_MESSAGE = "Enter an email address in the correct format, like name@example.com".freeze

  attribute :email

  validates :email, presence: { message: EMAIL_ADDRESS_PRESENCE_ERROR_MESSAGE }
  validates :email, length: { maximum: 512, message: EMAIL_ADDRESS_LENGTH_ERROR_MESSAGE },
                    format: { with: URI::MailTo::EMAIL_REGEXP, message: EMAIL_ADDRESS_FORMAT_ERROR_MESSAGE },
                    if: -> { email.present? }

  def submit
    validate!
    user = EarlyAccessUser.find_by(email:) || WaitingListUser.find_by(email:)
    return Result.new(outcome: :new_user, email:, user: nil) unless user
    return Result.new(outcome: :user_revoked, email:, user:) if user.try(:access_revoked?)

    if user.is_a?(EarlyAccessUser)
      session = Passwordless::Session.create!(authenticatable: user)
      EarlyAccessAuthMailer.sign_in(session).deliver_now
      Result.new(outcome: :existing_early_access_user, email:, user:)
    else
      Result.new(outcome: :existing_waiting_list_user, email:, user:)
    end
  end
end
