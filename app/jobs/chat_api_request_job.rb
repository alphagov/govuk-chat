class ChatApiRequestJob < ApplicationJob
  queue_as :default

  def perform(question_id:)
    question = Question.find(question_id)
    question.answer.create!(message: "Answer from chat-api")
  end
end
