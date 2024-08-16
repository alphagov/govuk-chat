class Admin::Form::WaitingListUsers::CreateWaitingListUserForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :email
  attribute :user_description
  attribute :reason_for_visit

  validates :email, presence: { message: "Enter an email address" }
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP, message: "Enter a valid email address" },
                    if: -> { email.present? }

  def submit
    validate!

    WaitingListUser.create!(email:, user_description:, reason_for_visit:, source: :admin_added)
  end
end
