class AddRevokedAtToEarlyAccessUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :early_access_users, :revoked_at, :datetime
  end
end
