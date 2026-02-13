class AddConversationSessionIdToQuestions < ActiveRecord::Migration[8.0]
  def change
    add_column :questions, :conversation_session_id, :uuid
  end
end
