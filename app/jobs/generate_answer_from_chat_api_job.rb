class GenerateAnswerFromChatApiJob < ApplicationJob
  queue_as :default

  def perform(question_id)
    question = Question.find_by(id: question_id)
    return logger.warn("No question found for #{question_id}") unless question
    return logger.warn("Question #{question_id} has already been answered") if question.answer

    answer = AnswerGeneration::GovukChatApi.call(question)
    answer.save!
  end
end
