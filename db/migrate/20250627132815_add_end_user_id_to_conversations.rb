class AddEndUserIdToConversations < ActiveRecord::Migration[8.0]
  def change
    add_column :conversations, :end_user_id, :string, null: true
  end
end
