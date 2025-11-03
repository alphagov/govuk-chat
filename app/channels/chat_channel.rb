class ChatChannel < ApplicationCable::Channel
  def subscribed
    stream_from "chat_#{params[:conversation_id]}_#{params[:question_id]}"
  end
end
