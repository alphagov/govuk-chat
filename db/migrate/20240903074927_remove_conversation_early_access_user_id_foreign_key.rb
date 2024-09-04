class RemoveConversationEarlyAccessUserIdForeignKey < ActiveRecord::Migration[7.2]
  def change
    remove_foreign_key :conversations, :early_access_users
  end
end
