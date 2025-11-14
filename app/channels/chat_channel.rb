class ChatChannel < ApplicationCable::Channel
  delegate :logger, to: Rails

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

  def cancelled(data)
    question = Question.includes(:answer).find_by(id: data["question_id"])

    if data["job_id"].present?
      logger.info("Cancelling received for job ID #{data['job_id']}")
      Sidekiq.redis { |c| c.set("cancelled-#{data['job_id']}", 1, ex: 600) }
    end

    unless question
      logger.warn("Cancel received for non-existent question ID #{data['question_id']}")
      return
    end

    Answer.find_or_initialize_by(question_id: question.id).tap do |answer|
      answer.cancelled_message = data["streamed_answer"].presence
      answer.cancelled = true
      answer.save!
    end
  end
end
