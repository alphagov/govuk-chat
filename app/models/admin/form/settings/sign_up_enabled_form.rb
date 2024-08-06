class Admin::Form::Settings::SignUpEnabledForm < Admin::Form::Settings::BaseForm
  attribute :enabled, :boolean

  def submit
    validate!
    return if settings.sign_up_enabled == enabled

    settings.locked_audited_update(user, action, author_comment) do
      settings.sign_up_enabled = enabled
    end
  end

private

  def action
    "Sign up enabled set to #{enabled}."
  end
end
