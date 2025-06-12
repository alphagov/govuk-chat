class RemovePublicAccessFromSettings < ActiveRecord::Migration[8.0]
  def change
    remove_column :settings, :public_access_enabled, :boolean, default: true, null: false
  end
end
