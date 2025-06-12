class Admin::Form::Settings::WebAccessForm < Admin::Form::Settings::BaseForm
  attribute :enabled, :boolean

  def submit
    validate!

    return if settings.web_access_enabled == enabled

    settings.locked_audited_update(user, action, author_comment) do
      settings.web_access_enabled = enabled
    end
  end

private

  def action
    "Web access enabled set to #{enabled}"
  end
end
