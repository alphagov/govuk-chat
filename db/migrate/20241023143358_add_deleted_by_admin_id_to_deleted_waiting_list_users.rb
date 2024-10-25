class AddDeletedByAdminIdToDeletedWaitingListUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :deleted_waiting_list_users, :deleted_by_admin_user_id, :uuid, null: true
  end
end
