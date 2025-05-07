class AddSourceToConversations < ActiveRecord::Migration[8.0]
  def change
    create_enum "conversation_source", %w[web api]
    add_column :conversations, :source, :conversation_source, null: false, default: "web"
  end
end
