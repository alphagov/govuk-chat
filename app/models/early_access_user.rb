class EarlyAccessUser < ApplicationRecord
  passwordless_with :email

  def access_revoked?
    revoked_at.present?
  end

  def sign_in(session)
    update!(last_login_at: Time.zone.now)
    passwordless_sessions.where.not(id: session.id).delete_all
  end
end
