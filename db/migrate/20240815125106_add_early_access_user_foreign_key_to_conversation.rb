class AddEarlyAccessUserForeignKeyToConversation < ActiveRecord::Migration[7.2]
  def change
    add_reference :conversations, :early_access_user, foreign_key: { null: true }, type: :uuid
  end
end
