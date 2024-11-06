class EarlyAccessUser < ApplicationRecord
  class AccessRevokedError < RuntimeError; end

  include PilotUser

  BANNABLE_ACTION_COUNT_THRESHOLD = 10
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

  scope :at_question_limit, lambda {
    default_limit = Rails.configuration.conversations.max_questions_per_user
    where(
      "(individual_question_limit IS NULL AND questions_count >= ?) OR (individual_question_limit > 0 AND questions_count >= individual_question_limit)",
      default_limit,
    )
  }

  scope :within_question_limit, lambda {
    default_limit = Rails.configuration.conversations.max_questions_per_user
    where(
      "(individual_question_limit IS NULL AND questions_count < ?) OR (questions_count < individual_question_limit) OR (individual_question_limit = 0)",
      default_limit,
    )
  }

  def self.promote_waiting_list_user(waiting_list_user, source = :admin_promoted)
    transaction do
      waiting_list_user.destroy_with_audit(deletion_type: :promotion)

      create!(
        **waiting_list_user.slice(:email, :user_description, :reason_for_visit, :previous_sign_up_denied),
        source:,
      )
    end
  end

  def self.aggregate_export_data(until_date)
    scope = where("created_at < ?", until_date)
    hash = {
      "exported_until" => until_date.as_json,
      "current_user_sources" => {},
      "deletion_types" => {},
      "revoked" => scope.where.not(revoked_at: nil).count,
    }

    source_counts = scope.group(:source).count
    sources.each_value do |source|
      hash["current_user_sources"][source] = source_counts[source] || 0
    end

    deletion_type_counts = DeletedEarlyAccessUser.where("created_at < ?", until_date).group(:deletion_type).count
    DeletedEarlyAccessUser.deletion_types.each_value do |deletion_type|
      hash["deletion_types"][deletion_type] = deletion_type_counts[deletion_type] || 0
    end

    hash["current"] = source_counts.sum(&:last)
    hash["deleted"] = deletion_type_counts.sum(&:last)
    hash["all_time"] = hash["current"] + hash["deleted"]

    hash
  end

  def destroy_with_audit(deletion_type:, deleted_by_admin_user_id: nil)
    transaction do
      destroy!
      DeletedEarlyAccessUser.create!(id:,
                                     deleted_by_admin_user_id:,
                                     deletion_type:,
                                     login_count:,
                                     user_source: source,
                                     user_created_at: created_at)
    end
  end

  def revoked?
    revoked_at.present?
  end

  def shadow_banned?
    shadow_banned_at.present?
  end

  def restored?
    restored_at.present?
  end

  def revoked_or_banned?
    revoked? || shadow_banned?
  end

  def sign_in(session)
    raise AccessRevokedError if revoked?

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

  def handle_jailbreak_attempt
    with_lock do
      self.bannable_action_count += 1
      if bannable_action_count >= BANNABLE_ACTION_COUNT_THRESHOLD
        assign_attributes(
          shadow_banned_at: Time.current,
          shadow_banned_reason: "#{bannable_action_count} jailbreak attempts made by user.",
          restored_at: nil,
          restored_reason: nil,
        )
      end

      save!

      SlackPoster.shadow_ban_notification(id) if shadow_banned?
    end
  end
end
