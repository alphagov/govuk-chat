class ChatChannel < ApplicationCable::Channel
  def subscribed
    stream_from "chat_#{params[:conversation_id]}_#{params[:question_id]}"
  end

  def answer(data)
    question = Question.includes(:answer).find_by(id: params[:question_id])

    if question.present? && question.answer.present?
      current_html = data["current_html"]
      message = question.answer.message

      if current_html.present?
        message = message.split(current_html).last
      end

      simulated_response = message.split(" ").map { |word| "#{word} " }
      simulated_response.each do |chunk|
        ActionCable.server.broadcast("chat_#{question.conversation_id}_#{question.id}", { message: chunk })
        sleep 0.05
      end

      ActionCable.server.broadcast("chat_#{question.conversation_id}_#{question.id}", { finished: true })
    else
      ActionCable.server.broadcast(
        "chat_#{question.conversation_id}_#{question.id}",
        answer: nil,
      )
    end
  end
end
