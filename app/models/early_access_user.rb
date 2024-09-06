class EarlyAccessUser < ApplicationRecord
  class AccessRevokedError < RuntimeError; end

  include PilotUser

  has_many :conversations
  passwordless_with :email

  enum :source,
       {
         admin_added: "admin_added",
         admin_promoted: "admin_promoted",
         delayed_signup: "delayed_signup",
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

  def question_limit_reached?
    return false if unlimited_question_allowance?

    number_of_questions_remaining <= 0
  end

  def number_of_questions_remaining
    raise "User has unlimited questions allowance" if unlimited_question_allowance?

    limit = question_limit || Rails.configuration.conversations.max_questions_per_user
    [limit - questions_count, 0].max
  end

  def unlimited_question_allowance?
    limit = question_limit || Rails.configuration.conversations.max_questions_per_user
    limit.zero?
  end
end
