class Admin::Form::WaitingListUserForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :email
  attribute :user_description, :string
  attribute :reason_for_visit, :string
  attribute :found_chat, :string
  attribute :user

  validates :email, presence: { message: "Enter an email address" },
                    if: -> { user.nil? }
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP, message: "Enter a valid email address" },
                    if: -> { email.present? }
  validates :reason_for_visit, inclusion: { in: WaitingListUser.reason_for_visit.keys,
                                            message: "Invalid Reason for visit option selected" },
                               allow_blank: true
  validates :user_description, inclusion: { in: WaitingListUser.user_descriptions.keys,
                                            message: "Invalid User description option selected" },
                               allow_blank: true
  validates :found_chat, inclusion: { in: WaitingListUser.found_chat.keys,
                                      message: "Invalid Found chat option selected" },
                         allow_blank: true
  validate :pilot_user_does_not_exist, if: -> { email.present? }

  def submit
    validate!

    if user.present?
      user.update!(email: email || user.email, user_description:, reason_for_visit:, found_chat:)
      user
    else
      WaitingListUser.create!(
        email:,
        user_description:,
        reason_for_visit:,
        found_chat:,
        source: :admin_added,
      )
    end
  end

private

  def pilot_user_does_not_exist
    if EarlyAccessUser.exists?(email:)
      errors.add(:email, "There is already an early access user with this email address")
      return
    end

    return unless WaitingListUser.where.not(id: user&.id).exists?(email:)

    errors.add(:email, "There is already a waiting list user with this email address")
  end
end
