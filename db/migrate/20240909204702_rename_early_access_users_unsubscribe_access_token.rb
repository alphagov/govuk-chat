class RenameEarlyAccessUsersUnsubscribeAccessToken < ActiveRecord::Migration[7.2]
  def change
    rename_column :early_access_users, :unsubscribe_access_token, :unsubscribe_token
  end
end
