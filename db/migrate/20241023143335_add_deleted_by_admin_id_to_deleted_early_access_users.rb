class AddDeletedByAdminIdToDeletedEarlyAccessUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :deleted_early_access_users, :deleted_by_signon_user_id, :uuid, null: true
  end
end
