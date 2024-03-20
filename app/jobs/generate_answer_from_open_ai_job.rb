class GenerateAnswerFromOpenAiJob < ApplicationJob
  queue_as :default

  def perform(question_id)
    question = Question.find(question_id)
    answer = AnswerGeneration::OpenaiRagCompletion.call(question.conversation)
    question.create_answer!(message: answer)
  end
end
