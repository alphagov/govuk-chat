class Admin::Form::WaitingListUsers::CreateWaitingListUserForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :email
  attribute :user_description
  attribute :reason_for_visit

  validates :email, presence: { message: "Enter an email address" }
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP, message: "Enter a valid email address" },
                    if: -> { email.present? }
  validate :pilot_user_does_not_exist, if: -> { email.present? }

  def submit
    validate!

    WaitingListUser.create!(email:, user_description:, reason_for_visit:, source: :admin_added)
  end

private

  def pilot_user_does_not_exist
    return unless WaitingListUser.exists?(email:) || EarlyAccessUser.exists?(email:)

    errors.add(:email, "There is already a pilot user with this email address")
  end
end
