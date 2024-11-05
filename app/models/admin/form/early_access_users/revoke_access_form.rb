class Admin::Form::EarlyAccessUsers::RevokeAccessForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :revoke_reason, :string
  attribute :user

  REVOKE_REASON_PRESENCE_ERROR_MESSAGE = "Enter a reason for revoking access".freeze
  REVOKE_REASON_LENGTH_MAXIMUM = 255
  REVOKE_REASON_LENGTH_ERROR_MESSAGE = "Revoke reason must be %{count} characters or less".freeze

  validates :revoke_reason, presence: { message: REVOKE_REASON_PRESENCE_ERROR_MESSAGE }
  validates :revoke_reason, length: { maximum: REVOKE_REASON_LENGTH_MAXIMUM, message: REVOKE_REASON_LENGTH_ERROR_MESSAGE }

  def submit
    validate!

    user.update!(
      revoked_at: Time.zone.now,
      revoked_reason: revoke_reason,
      restored_at: nil,
      restored_reason: nil,
    )
  end
end
