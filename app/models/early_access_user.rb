class EarlyAccessUser < ApplicationRecord
  class AccessRevokedError < RuntimeError; end

  passwordless_with :email

  enum :source,
       {
         admin_added: "admin_added",
         instant_signup: "instant_signup",
       },
       prefix: true

  enum :user_description,
       {
         business_owner_or_self_employed: "business_owner_or_self_employed",
         starting_business_or_becoming_self_employed: "starting_business_or_becoming_self_employed",
         business_advisor: "business_advisor",
         business_administrator: "business_administrator",
         none: "none",
       },
       prefix: true

  enum :reason_for_visit,
       {
         find_specific_answer: "find_specific_answer",
         complete_task: "complete_task",
         understand_process: "understand_process",
         research_topic: "research_topic",
         other: "other",
       },
       prefix: true

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
