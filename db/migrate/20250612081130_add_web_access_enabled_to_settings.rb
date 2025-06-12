class AddWebAccessEnabledToSettings < ActiveRecord::Migration[8.0]
  def change
    add_column :settings, :web_access_enabled, :boolean, default: true
  end
end
