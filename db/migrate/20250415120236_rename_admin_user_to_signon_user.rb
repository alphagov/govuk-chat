class RenameAdminUserToSignonUser < ActiveRecord::Migration[8.0]
  def change
    rename_table :admin_users, :signon_users
    rename_column :deleted_early_access_users, :deleted_by_admin_user_id, :deleted_by_signon_user_id
    rename_column :deleted_waiting_list_users, :deleted_by_admin_user_id, :deleted_by_signon_user_id
  end
end
