class MakeConversationSessionIdNonNullable < ActiveRecord::Migration[8.0]
  def change
    change_column_null :questions, :conversation_session_id, false
  end
end
