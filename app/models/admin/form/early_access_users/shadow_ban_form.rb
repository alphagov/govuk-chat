class Admin::Form::EarlyAccessUsers::ShadowBanForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :shadow_ban_reason, :string
  attribute :user

  SHADOW_BAN_REASON_PRESENCE_ERROR_MESSAGE = "Enter a reason for shadow banning the user".freeze
  SHADOW_BAN_REASON_LENGTH_MAXIMUM = 255
  SHADOW_BAN_REASON_LENGTH_ERROR_MESSAGE = "Shadow ban reason must be %{count} characters or less".freeze

  validates :shadow_ban_reason, presence: { message: SHADOW_BAN_REASON_PRESENCE_ERROR_MESSAGE }
  validates :shadow_ban_reason, length: { maximum: SHADOW_BAN_REASON_LENGTH_MAXIMUM, message: SHADOW_BAN_REASON_LENGTH_ERROR_MESSAGE }

  def submit
    validate!

    user.update!(
      shadow_banned_at: Time.zone.now,
      shadow_banned_reason: shadow_ban_reason,
      restored_at: nil,
      restored_reason: nil,
    )
  end
end
