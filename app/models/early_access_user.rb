class EarlyAccessUser < ApplicationRecord
  class AccessRevokedError < RuntimeError; end

  include PilotUser

  has_many :conversations
  passwordless_with :email

  enum :source,
       {
         admin_added: "admin_added",
         instant_signup: "instant_signup",
       },
       prefix: true

  passwordless_with :email

  def access_revoked?
    revoked_at.present?
  end

  def sign_in(session)
    raise AccessRevokedError if access_revoked?

    touch(:last_login_at)

    # delete any other sessions for this user to ensure no concurrent sessions,
    # both active and ones not yet to be claimed
    Passwordless::Session.available
                         .where(authenticatable: self)
                         .where.not(id: session.id)
                         .delete_all
  end
end
