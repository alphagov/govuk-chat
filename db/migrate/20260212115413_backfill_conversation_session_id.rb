class BackfillConversationSessionId < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  def up
    Conversation.joins(:questions)
                .where(questions: { conversation_session_id: nil })
                .distinct
                .find_each do |conversation|
                  last_session_id = nil
                  last_created_at = nil

                  Question.where(conversation:).order(:created_at).each do |question|
                    if last_created_at.nil? || last_created_at < question.created_at - 30.minutes
                      last_session_id = SecureRandom.uuid
                    end

                    question.update_columns(conversation_session_id: last_session_id)

                    last_created_at = question.created_at
                  end
    end
  end

  def down
    Question.update_all(conversation_session_id: nil)
  end
end
