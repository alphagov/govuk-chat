class Admin::Form::EarlyAccessUsers::CreateForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :email

  validates :email, presence: { message: "Enter an email address" }
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP, message: "Enter a valid email address" },
                    if: -> { email.present? }
  validate :email_must_be_unique, if: -> { email.present? }

  def submit
    validate!

    user = EarlyAccessUser.create!(email:, source: :admin_added)

    session = Passwordless::Session.create!(authenticatable: user)
    EarlyAccessAuthMailer.sign_in(session).deliver_now

    WaitingListUser.where(email:).delete_all

    user
  end

private

  def email_must_be_unique
    return if EarlyAccessUser.where(email:).blank?

    errors.add(:email, "Email address already exists")
  end
end
