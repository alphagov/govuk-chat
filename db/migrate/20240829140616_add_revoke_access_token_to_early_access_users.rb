class AddRevokeAccessTokenToEarlyAccessUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :early_access_users, :revoke_access_token, :string, null: false, default: -> { "gen_random_uuid()" }
  end
end
