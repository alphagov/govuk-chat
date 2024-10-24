class WaitingListUser < ApplicationRecord
  include PilotUser

  SOURCE_ENUM = {
    admin_added: "admin_added",
    insufficient_instant_places: "insufficient_instant_places",
  }.freeze

  enum :source, SOURCE_ENUM, prefix: true

  scope :users_to_promote, ->(limit) { order("RANDOM()").limit(limit) }

  def self.aggregate_export_data(until_date)
    hash = {
      "exported_until" => until_date.as_json,
      "current_user_sources" => {},
      "deletion_types" => {},
    }

    source_counts = where("created_at < ?", until_date).group(:source).count
    sources.each_value do |source|
      hash["current_user_sources"][source] = source_counts[source] || 0
    end

    deletion_type_counts = DeletedWaitingListUser.where("created_at < ?", until_date).group(:deletion_type).count
    DeletedWaitingListUser.deletion_types
                          .each_value do |deletion_type|
                            hash["deletion_types"][deletion_type] = deletion_type_counts[deletion_type] || 0
                          end

    hash["current"] = source_counts.sum(&:last)
    hash["deleted"] = deletion_type_counts.sum(&:last)
    hash["all_time"] = hash["current"] + hash["deleted"]

    hash
  end

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
