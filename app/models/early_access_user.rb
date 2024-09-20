class EarlyAccessUser < ApplicationRecord
  class AccessRevokedError < RuntimeError; end

  include PilotUser

  SOURCE_ENUM = {
    admin_added: "admin_added",
    admin_promoted: "admin_promoted",
    delayed_signup: "delayed_signup",
    instant_signup: "instant_signup",
  }.freeze

  has_many :conversations
  passwordless_with :email

  enum :source, SOURCE_ENUM, prefix: true

  passwordless_with :email

  def self.promote_waiting_list_user(waiting_list_user, source = :admin_promoted)
    transaction do
      waiting_list_user.destroy_with_audit(deletion_type: :promotion)

      create!(
        **waiting_list_user.slice(:email, :user_description, :reason_for_visit),
        source:,
      )
    end
  end

  def destroy_with_audit(deletion_type:)
    transaction do
      destroy!
      DeletedEarlyAccessUser.create!(id:,
                                     deletion_type:,
                                     login_count:,
                                     user_source: source,
                                     user_created_at: created_at)
    end
  end

  def access_revoked?
    revoked_at.present?
  end

  def sign_in(session)
    raise AccessRevokedError if access_revoked?

    touch(:last_login_at)
    increment!(:login_count)

    # delete any other sessions for this user to ensure no concurrent sessions,
    # both active and ones not yet to be claimed
    Passwordless::Session.available
      .where(authenticatable: self)
      .where.not(id: session.id)
      .delete_all

    Metrics.increment_counter("login_total", user_source: source)
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
