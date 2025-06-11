class Admin::Form::Settings::PublicAccessForm < Admin::Form::Settings::BaseForm
  attribute :enabled, :boolean

  def submit
    validate!

    return if settings.public_access_enabled == enabled

    settings.locked_audited_update(user, action, author_comment) do
      settings.public_access_enabled = enabled
    end
  end

private

  def action
    "Public access enabled set to #{enabled}"
  end
end
