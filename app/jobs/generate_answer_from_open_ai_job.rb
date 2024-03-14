class GenerateAnswerFromOpenAiJob < ApplicationJob
  queue_as :default

  def perform(question_id:)
    question = Question.find(question_id)
    question.answer.create!(message: "Answer from OpenAI")
  end
end
