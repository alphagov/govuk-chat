class CreateConversations < ActiveRecord::Migration[7.1]
  def change
    enable_extension "pgcrypto"

    create_table :conversations, id: :uuid, &:timestamps

    add_index :conversations, :created_at
  end
end
