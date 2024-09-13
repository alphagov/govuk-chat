class AddLoginCountToEarlyAccessUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :early_access_users, :login_count, :integer, default: 0
  end
end
