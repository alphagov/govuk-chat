class Admin::Form::EarlyAccessUsers::CreateEarlyAccessUserForm
  include ActiveModel::Model

  attr_accessor :email

  validates :email, presence: { message: "Enter an email address" }
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP, message: "Enter a valid email address" },
                    if: -> { email.present? }

  def submit
    validate!

    user = EarlyAccessUser.create!(email:, source: :admin_added)

    session = Passwordless::Session.create!(authenticatable: user)
    EarlyAccessAuthMailer.sign_in(session).deliver_now

    user
  end
end
