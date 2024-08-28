class EarlyAccessUser < ApplicationRecord
  class AccessRevokedError < RuntimeError; end

  include PilotUser

  has_many :conversations
  passwordless_with :email

  enum :source,
       {
         admin_added: "admin_added",
         admin_promoted: "admin_promoted",
         instant_signup: "instant_signup",
       },
       prefix: true

  passwordless_with :email

  def self.promote_waiting_list_user(waiting_list_user, source = :admin_promoted)
    transaction do
      waiting_list_user.destroy!

      create!(
        **waiting_list_user.slice(:email, :user_description, :reason_for_visit),
        source:,
      )
    end
  end

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
