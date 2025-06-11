class RemoveDowntimeTypeFromSettings < ActiveRecord::Migration[8.0]
  def change
    remove_column :settings, :downtime_type, :integer, null: false, default: 0
    drop_enum :settings_downtime_type, prefix: true, suffix: true
  end
end
