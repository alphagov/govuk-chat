class RenameRevokeAccessTokenToUnsubscibeAccessToken < ActiveRecord::Migration[7.2]
  def change
    rename_column :early_access_users, :revoke_access_token, :unsubscribe_access_token
  end
end
