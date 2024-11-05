class Admin::Form::EarlyAccessUsers::RestoreAccessForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :restored_reason, :string
  attribute :user

  RESTORED_REASON_PRESENCE_ERROR_MESSAGE = "Enter a reason for restoring access".freeze
  RESTORED_REASON_LENGTH_MAXIMUM = 255
  RESTORED_REASON_LENGTH_ERROR_MESSAGE = "Restored reason must be %{count} characters or less".freeze

  validates :restored_reason, presence: { message: RESTORED_REASON_PRESENCE_ERROR_MESSAGE }
  validates :restored_reason, length: { maximum: RESTORED_REASON_LENGTH_MAXIMUM, message: RESTORED_REASON_LENGTH_ERROR_MESSAGE }

  def submit
    validate!

    user.update!(
      restored_at: Time.current,
      restored_reason:,
      revoked_at: nil,
      revoked_reason: nil,
      shadow_banned_at: nil,
      shadow_banned_reason: nil,
      bannable_action_count: 0,
    )
  end
end
