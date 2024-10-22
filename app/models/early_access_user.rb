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

  def self.aggregate_export_data(until_date)
    scope = where("created_at < ?", until_date)
    hash = {
      "exported_until" => until_date.as_json,
      "revoked" => scope.where.not(revoked_at: nil).count,
    }

    source_counts = scope.group(:source).count
    sources.each_value do |source|
      hash[source] = source_counts[source] || 0
    end

    deletion_type_counts = DeletedEarlyAccessUser.where("created_at < ?", until_date).group(:deletion_type).count
    DeletedEarlyAccessUser.deletion_types.each_value do |deletion_type|
      hash["deleted_by_#{deletion_type}"] = deletion_type_counts[deletion_type] || 0
    end

    hash
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
  end

  def question_limit
    individual_question_limit || Rails.configuration.conversations.max_questions_per_user
  end

  def question_limit_reached?
    return false if unlimited_question_allowance?

    questions_remaining <= 0
  end

  def questions_remaining
    raise "User has unlimited questions allowance" if unlimited_question_allowance?

    [question_limit - questions_count, 0].max
  end

  def unlimited_question_allowance?
    question_limit.zero?
  end
end
