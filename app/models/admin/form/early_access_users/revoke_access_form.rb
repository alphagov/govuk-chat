class Admin::Form::EarlyAccessUsers::RevokeAccessForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :revoke_reason, :string
  attribute :user

  validates :revoke_reason, presence: { message: "Enter a reason for revoking access" }

  def submit
    validate!

    user.update!(
      revoked_at: Time.zone.now,
      revoked_reason: revoke_reason,
    )
  end
end
