class AddDowntimeTypeToSettings < ActiveRecord::Migration[7.1]
  def change
    create_enum :settings_downtime_type, %w[temporary permanent]
    add_column :settings, :downtime_type, :enum, enum_type: :settings_downtime_type, default: :temporary
  end
end
