class RemoveEarlyAccessUserIdFromConversations < ActiveRecord::Migration[8.0]
  def up
    remove_column :conversations, :early_access_user_id
  end

  def down
    add_column :conversations, :early_access_user_id, :uuid
    add_index :conversations, :early_access_user_id
  end
end
