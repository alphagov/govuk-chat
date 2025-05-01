class AddSignonUserForeignKeyToConversation < ActiveRecord::Migration[8.0]
  def change
    add_reference :conversations, :signon_user, foreign_key: { null: true, on_delete: :restrict }, type: :uuid
  end
end
