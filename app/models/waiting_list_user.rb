class WaitingListUser < ApplicationRecord
  include PilotUser

  SOURCE_ENUM = {
    admin_added: "admin_added",
    insufficient_instant_places: "insufficient_instant_places",
  }.freeze

  enum :source, SOURCE_ENUM, prefix: true

  scope :users_to_promote, ->(limit) { order("RANDOM()").limit(limit) }

  def destroy_with_audit(deletion_type:)
    transaction do
      destroy!
      DeletedWaitingListUser.create!(id:,
                                     deletion_type:,
                                     user_source: source,
                                     user_created_at: created_at)
    end
  end
end
