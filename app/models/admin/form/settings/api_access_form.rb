class Admin::Form::Settings::ApiAccessForm < Admin::Form::Settings::BaseForm
  attribute :enabled, :boolean

  def submit
    return if settings.api_access_enabled == enabled

    settings.locked_audited_update(user, action, author_comment) do
      settings.api_access_enabled = enabled
    end
  end

private

  def action
    "API access enabled set to #{enabled}"
  end
end
