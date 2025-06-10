class AddApiAccessEnabledToSettings < ActiveRecord::Migration[8.0]
  def change
    add_column :settings, :api_access_enabled, :boolean, default: true
  end
end
