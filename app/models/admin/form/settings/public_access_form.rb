class Admin::Form::Settings::PublicAccessForm < Admin::Form::Settings::BaseForm
  attribute :enabled, :boolean
  attribute :downtime_type, :string

  validates :downtime_type, inclusion: { in: Settings.downtime_types.keys,
                                         message: "Downtime type option must be selected" }

  def submit
    validate!
    return if settings.public_access_enabled == enabled && settings.downtime_type.to_s == downtime_type

    settings.locked_audited_update(user, action, author_comment) do
      settings.public_access_enabled = enabled
      settings.downtime_type = downtime_type
    end
  end

private

  def action
    if settings.public_access_enabled != enabled
      action_text = "Public access enabled set to #{enabled}"
      action_text += ", downtime type #{downtime_type}" unless enabled

      action_text
    else
      "Downtime type set to #{downtime_type}"
    end
  end
end
