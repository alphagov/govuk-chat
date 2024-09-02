class AddUnsubscribeTokenToWaitingListUser < ActiveRecord::Migration[7.2]
  def change
    # We're setting a non-null default value for the column, so we need to delete all existing records
    WaitingListUser.delete_all

    add_column :waiting_list_users, :unsubscribe_token, :string, null: false, default: -> { "gen_random_uuid()" }
  end
end
