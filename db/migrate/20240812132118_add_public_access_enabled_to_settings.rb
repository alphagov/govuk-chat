class AddPublicAccessEnabledToSettings < ActiveRecord::Migration[7.1]
  def change
    add_column :settings, :public_access_enabled, :boolean, default: true
  end
end
