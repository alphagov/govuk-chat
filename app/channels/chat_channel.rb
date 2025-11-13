class ChatChannel < ApplicationCable::Channel
  def subscribed
    stream_from "chat_#{params[:conversation_id]}"
  end

  def answer(data)
    question = Question.includes(:answer).find_by(id: data["question_id"])

    if question.present? && question.answer.present?
      current_html = data["current_html"]
      message = question.answer.message

      if current_html.present?
        message = message.split(current_html).last
      end

      simulated_response = message.split(" ").map { |word| "#{word} " }
      simulated_response.each do |chunk|
        ActionCable.server.broadcast("chat_#{question.conversation_id}", { question_id: question.id, message: chunk })
        sleep 0.05
      end

      ActionCable.server.broadcast("chat_#{question.conversation_id}", { question_id: question.id, finished: true })
    else
      ActionCable.server.broadcast(
        "chat_#{question.conversation_id}",
        answer: nil,
      )
    end
  end
end
