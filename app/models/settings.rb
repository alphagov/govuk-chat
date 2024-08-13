class Settings < ApplicationRecord
  validates :singleton_guard, inclusion: { in: [0] }, strict: true
  enum :downtime_type,
       {
         temporary: "temporary",
         permanent: "permanent",
       },
       prefix: true

  def self.instance
    first_or_create!
  end

  def locked_audited_update(audit_user, audit_action, audit_comment)
    with_lock do
      yield
      save!
      SettingsAudit.create!(
        user: audit_user,
        action: audit_action,
        author_comment: audit_comment,
      )
    end
  end
end
