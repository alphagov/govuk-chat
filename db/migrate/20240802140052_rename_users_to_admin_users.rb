class RenameUsersToAdminUsers < ActiveRecord::Migration[7.1]
  def change
    rename_table :users, :admin_users
  end
end
