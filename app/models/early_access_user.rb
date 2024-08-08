class EarlyAccessUser < ApplicationRecord
  passwordless_with :email

  def sign_in(session)
    update!(last_login: Time.zone.now)
    passwordless_sessions.where.not(id: session.id).delete_all
  end
end
